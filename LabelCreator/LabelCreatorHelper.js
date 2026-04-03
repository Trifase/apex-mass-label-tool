/**
 * Created by Luca Bellanti on 2026-04-03.
 */

({
	addEmptyRows: function (component, count) {
		let rows = component.get('v.rows');
		for (let i = 0; i < count; i++) {
			rows.push({
				apiName: '',
				category: '',
				englishValue: '',
				translationValue: '',
				status: '',
				statusMessage: ''
			});
		}
		component.set('v.rows', rows);
	},

	/**
	 * Initializes sequential processing for both create and translate modes.
	 */
	startProcessing: function (component, validRowIndices, mode) {
		component.set('v.isProcessing', true);
		component.set('v.processedCount', 0);
		component.set('v.successCount', 0);
		component.set('v.totalToProcess', validRowIndices.length);
		component.set('v.currentProcessingIndex', 0);

		component._validRowIndices = validRowIndices;
		component._translationLanguage = component.get('v.translationLanguage');
		component._processingMode = mode; // 'create' or 'translate'

		this.processNext(component);
	},

	/**
	 * Processes rows one-by-one. Calls createSingleLabel or translateExistingLabel
	 * depending on the stored mode.
	 */
	processNext: function (component) {
		let helper = this;
		let queueIndex = component.get('v.currentProcessingIndex');
		let validIndices = component._validRowIndices;

		// All done?
		if (queueIndex >= validIndices.length) {
			component.set('v.isProcessing', false);
			let success = component.get('v.successCount');
			let total = component.get('v.totalToProcess');
			let failed = total - success;
			let isTranslate = component._processingMode === 'translate';
			let noun = isTranslate ? 'translation(s)' : 'label(s)';
			let msg = success + ' ' + noun + ' created successfully.';
			if (failed > 0) {
				msg += ' ' + failed + ' failed.';
			}
			helper.showToast(
				failed === 0 ? 'Success' : 'Completed with errors',
				msg,
				failed === 0 ? 'success' : 'warning'
			);
			return;
		}

		let rowIndex = validIndices[queueIndex];
		let rows = component.get('v.rows');
		let row = rows[rowIndex];

		// Mark row as processing
		row.status = 'processing';
		row.statusMessage = '';
		component.set('v.rows', rows);

		// Build server action based on mode
		let action;
		let translationLang = component._translationLanguage || '';

		if (component._processingMode === 'translate') {
			action = component.get('c.translateExistingLabel');
			action.setParams({
				apiName: row.apiName.trim(),
				translationValue: row.translationValue.trim(),
				translationLanguage: translationLang,
				localizationId: row.localizationId || null
			});
		} else {
			action = component.get('c.createSingleLabel');
			action.setParams({
				apiName: row.apiName.trim(),
				category: row.category ? row.category.trim() : '',
				englishValue: row.englishValue.trim(),
				translationValue: row.translationValue ? row.translationValue.trim() : '',
				translationLanguage: translationLang
			});
		}

		action.setCallback(this, function (response) {
			let state = response.getState();
			let currentRows = component.get('v.rows');

			if (state === 'SUCCESS') {
				let result = response.getReturnValue();
				if (result.success) {
					currentRows[rowIndex].status = 'success';
					currentRows[rowIndex].statusMessage = result.message;
					component.set('v.successCount', component.get('v.successCount') + 1);
				} else {
					currentRows[rowIndex].status = 'error';
					currentRows[rowIndex].statusMessage = result.message;
				}
			} else {
				let errors = response.getError();
				let errMsg = errors && errors[0] && errors[0].message ? errors[0].message : 'Unknown error';
				currentRows[rowIndex].status = 'error';
				currentRows[rowIndex].statusMessage = errMsg;
			}

			component.set('v.rows', currentRows);
			component.set('v.processedCount', component.get('v.processedCount') + 1);

			// Move to next
			component.set('v.currentProcessingIndex', queueIndex + 1);
			helper.processNext(component);
		});

		$A.enqueueAction(action);
	},

	clearTranslationsOnRows: function (component) {
		let rows = component.get('v.rows');
		for (let i = 0; i < rows.length; i++) {
			rows[i].localizationId = null;
			rows[i].translationValue = '';
		}
		component.set('v.rows', rows);
	},

	fetchLabelDataFromServer: function (component, rowIndex) {
		let helper = this;
		let rows = component.get('v.rows');
		let row = rows[rowIndex];
		let lang = component.get('v.translationLanguage');

		if (!row.apiName) return;

		let action = component.get('c.fetchLabelData');
		action.setParams({
			apiName: row.apiName.trim(),
			language: lang
		});

		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === 'SUCCESS') {
				let result = response.getReturnValue();
				let currentRows = component.get('v.rows');
				if (result.found) {
					currentRows[rowIndex].englishValue = result.englishValue;
					currentRows[rowIndex].labelId = result.labelId;
					currentRows[rowIndex].setupLink = '/lightning/setup/ExternalStrings/page?address=%2F' + result.labelId;
					if (result.localizationId) {
						currentRows[rowIndex].localizationId = result.localizationId;
						currentRows[rowIndex].translationValue = result.translationValue;
					}
					component.set('v.rows', currentRows);
					helper.showToast('Success', 'Label data fetched for ' + row.apiName, 'success');
				} else {
					helper.showToast('Error', 'Label not found: ' + row.apiName, 'error');
				}
			} else {
				let errors = response.getError();
				let errMsg = errors && errors[0] && errors[0].message ? errors[0].message : 'Unknown error';
				helper.showToast('Error', 'Failed to fetch label: ' + errMsg, 'error');
			}
		});

		$A.enqueueAction(action);
	},

	showToast: function (title, message, type) {
		let toastEvent = $A.get('e.force:showToast');
		toastEvent.setParams({ title: title, message: message, type: type });
		toastEvent.fire();
	}
})
