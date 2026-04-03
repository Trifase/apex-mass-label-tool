/**
 * Created by Luca Bellanti on 2026-04-03.
 */

/**
 * Apex controller for the LabelCreator Aura component.
 * Processes one label at a time to allow real-time progress updates on the UI.
 * Uses LabelUtils for the actual label + translation creation via the Tooling API.
 */
public class LabelCreatorController {

	@AuraEnabled
	public static Map<String, Object> createSingleLabel(String apiName, String category, String englishValue, String translationValue, String translationLanguage) {
		Map<String, Object> result = new Map<String, Object>();
		result.put('apiName', apiName);

		try {
			// Sanitize API name: replace spaces with underscores
			String cleanApiName = apiName.trim().replace(' ', '_');

			LabelUtils.LabelWrapper wrapper = new LabelUtils.LabelWrapper();
			wrapper.Name = cleanApiName;
			wrapper.MasterLabel = cleanApiName;
			wrapper.Value = englishValue;
			wrapper.Category = String.isNotBlank(category) ? category.trim() : '';
			wrapper.Language = 'en_US';
			wrapper.isProtected = 'false';

			String labelId = LabelUtils.createLabel(wrapper);

			if (labelId != null && !labelId.startsWith('KO')) {
				result.put('success', true);
				String message = 'Label created';

				// Create translation if value and language are provided
				if (String.isNotBlank(translationValue) && String.isNotBlank(translationLanguage)) {
					String translResult = LabelUtils.createTranslation(labelId, translationLanguage, translationValue.trim());
					if (translResult == 'OK') {
						message += ' + ' + translationLanguage.toUpperCase() + ' translation';
					} else {
						message += ' (' + translationLanguage.toUpperCase() + ' failed: ' + translResult + ')';
					}
				}

				result.put('message', message);
			} else {
				result.put('success', false);
				result.put('message', labelId);
			}
		} catch (Exception e) {
			result.put('success', false);
			result.put('message', e.getMessage());
		}

		return result;
	}

	/**
	 * Translates an existing custom label.
	 * 1. Queries the Tooling API for the ExternalString Id by API name
	 * 2. Checks if a translation already exists for the target language
	 * 3. Creates (POST) or updates (PATCH) the translation
	 */
	@AuraEnabled
	public static Map<String, Object> translateExistingLabel(String apiName, String translationValue, String translationLanguage, String localizationId) {
		Map<String, Object> result = new Map<String, Object>();
		result.put('apiName', apiName);

		try {
			String cleanApiName = apiName.trim().replace(' ', '_');
			String sessionId = LabelUtils.getApiSessionId();
			String baseUrl = Url.getOrgDomainUrl().toExternalForm();

			String labelId;
			// If we don't have a localizationId, we still need to find the labelId
			if (String.isBlank(localizationId)) {
				String query = 'SELECT Id, Name FROM ExternalString WHERE Name = \'' + String.escapeSingleQuotes(cleanApiName) + '\'';
				HttpRequest req = new HttpRequest();
				req.setHeader('Authorization', 'Bearer ' + sessionId);
				req.setHeader('Content-Type', 'application/json');
				req.setEndpoint(baseUrl + '/services/data/v56.0/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
				req.setMethod('GET');

				Http http = new Http();
				HttpResponse res = http.send(req);

				if (res.getStatusCode() == 200) {
					Map<String, Object> queryResult = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
					List<Object> records = (List<Object>) queryResult.get('records');
					if (records != null && !records.isEmpty()) {
						Map<String, Object> labelRecord = (Map<String, Object>) records[0];
						labelId = (String) labelRecord.get('Id');
					}
				}

				if (labelId == null) {
					result.put('success', false);
					result.put('message', 'Label not found: ' + cleanApiName);
					return result;
				}

				// Check if translation exists if we didn't get a localizationId from the UI
				String locQuery = 'SELECT Id FROM ExternalStringLocalization WHERE ExternalStringId = \'' + labelId + '\' AND Language = \'' + translationLanguage + '\'';
				HttpRequest locReq = new HttpRequest();
				locReq.setHeader('Authorization', 'Bearer ' + sessionId);
				locReq.setHeader('Content-Type', 'application/json');
				locReq.setEndpoint(baseUrl + '/services/data/v56.0/tooling/query/?q=' + EncodingUtil.urlEncode(locQuery, 'UTF-8'));
				locReq.setMethod('GET');

				HttpResponse locRes = http.send(locReq);
				if (locRes.getStatusCode() == 200) {
					Map<String, Object> locQueryResult = (Map<String, Object>) JSON.deserializeUntyped(locRes.getBody());
					List<Object> locRecords = (List<Object>) locQueryResult.get('records');
					if (locRecords != null && !locRecords.isEmpty()) {
						Map<String, Object> locRecord = (Map<String, Object>) locRecords[0];
						localizationId = (String) locRecord.get('Id');
					}
				}
			}

			// Perform Create or Update
			String translResult;
			if (String.isNotBlank(localizationId)) {
				translResult = LabelUtils.updateTranslation(localizationId, translationValue.trim());
			} else {
				translResult = LabelUtils.createTranslation(labelId, translationLanguage, translationValue.trim());
			}

			if (translResult == 'OK') {
				result.put('success', true);
				result.put('message', (String.isNotBlank(localizationId) ? 'Translation updated' : 'Translation created'));
			} else {
				result.put('success', false);
				result.put('message', translResult);
			}
		} catch (Exception e) {
			result.put('success', false);
			result.put('message', e.getMessage());
		}

		return result;
	}

	/**
	 * Fetches label data (English value and existing translation) for a given API name.
	 */
	@AuraEnabled
	public static Map<String, Object> fetchLabelData(String apiName, String language) {
		Map<String, Object> result = new Map<String, Object>();
		try {
			String cleanApiName = apiName.trim().replace(' ', '_');
			String sessionId = LabelUtils.getApiSessionId();
			String baseUrl = Url.getOrgDomainUrl().toExternalForm();

			// 1. Get Label
			String query = 'SELECT Id, Name, Value FROM ExternalString WHERE Name = \'' + String.escapeSingleQuotes(cleanApiName) + '\'';
			HttpRequest req = new HttpRequest();
			req.setHeader('Authorization', 'Bearer ' + sessionId);
			req.setHeader('Content-Type', 'application/json');
			req.setEndpoint(baseUrl + '/services/data/v56.0/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
			req.setMethod('GET');

			Http http = new Http();
			HttpResponse res = http.send(req);

			if (res.getStatusCode() != 200) {
				throw new AuraHandledException('Failed to fetch label: ' + res.getBody());
			}

			Map<String, Object> queryResult = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
			List<Object> records = (List<Object>) queryResult.get('records');

			if (records == null || records.isEmpty()) {
				result.put('found', false);
				return result;
			}

			Map<String, Object> labelRecord = (Map<String, Object>) records[0];
			String labelId = (String) labelRecord.get('Id');
			result.put('found', true);
			result.put('labelId', labelId);
			result.put('englishValue', (String) labelRecord.get('Value'));

			// 2. Get Translation
			if (String.isNotBlank(language)) {
				String locQuery = 'SELECT Id, Value FROM ExternalStringLocalization WHERE ExternalStringId = \'' + labelId + '\' AND Language = \'' + language + '\'';
				HttpRequest locReq = new HttpRequest();
				locReq.setHeader('Authorization', 'Bearer ' + sessionId);
				locReq.setHeader('Content-Type', 'application/json');
				locReq.setEndpoint(baseUrl + '/services/data/v56.0/tooling/query/?q=' + EncodingUtil.urlEncode(locQuery, 'UTF-8'));
				locReq.setMethod('GET');

				HttpResponse locRes = http.send(locReq);
				if (locRes.getStatusCode() == 200) {
					Map<String, Object> locQueryResult = (Map<String, Object>) JSON.deserializeUntyped(locRes.getBody());
					List<Object> locRecords = (List<Object>) locQueryResult.get('records');
					if (locRecords != null && !locRecords.isEmpty()) {
						Map<String, Object> locRecord = (Map<String, Object>) locRecords[0];
						result.put('localizationId', (String) locRecord.get('Id'));
						result.put('translationValue', (String) locRecord.get('Value'));
					}
				}
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return result;
	}
}
