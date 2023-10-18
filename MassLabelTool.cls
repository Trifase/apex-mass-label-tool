/**
 * Created by Luca Bellanti on 2023-10-13.
 */

public class MassLabelTool {


    // This is used to mass create a list of LabelWrapper from a textblock in a CSV-fashion like this:
    // LabelName;LabelCategory;LabelValue
    // LabelName2;LabelCategory2;LabelValue2
    // ...

    public static List<LabelWrapper> makeLabelListfromCSV(String textblock) {
        List<LabelWrapper> labels = new List<LabelWrapper>();
        List<String> lines = textblock.split('\n');
        for (String line : lines) {
            List<String> fields = line.split(';');
            LabelWrapper label = new LabelWrapper();
            label.Name = fields[0];
            label.MasterLabel = fields[0];
            label.Value = fields[2];
            label.isProtected = 'false';
            label.Language = 'en_US';
            label.Category = fields[1];
            labels.add(label);
        }
        return labels;
    }

    // This is used to mass create labels from a list of LabelWrapper
    public static void createLabels(List<LabelWrapper> labels) {
        List<LabelWrapper> labelsOK = new List<LabelWrapper>();
        List<LabelWrapper> labelsKO = new List<LabelWrapper>();
        for (LabelWrapper label : labels) {

            if (label.Language == null) {
                label.Language = 'en_US';
            }
            if (label.MasterLabel == null) {
                label.MasterLabel = label.Name;
            }
            if (label.isProtected == null) {
                label.isProtected = 'false';
            }

            // Replace whitespaces
            if (label.Name.contains(' ')) {
                label.Name = label.Name.replace(' ', '_');
            }
            if (label.MasterLabel.contains(' ')) {
                label.MasterLabel = label.MasterLabel.replace(' ', '_');
            }

            if (String.isEmpty(label.Name) || String.isEmpty(label.MasterLabel) || String.isEmpty(label.Value)) {
                labelsKO.add(label);
            } else {
                labelsOK.add(label);
            }
        }

        if (labelsOK.size() > 0) {
            for (LabelWrapper label : labelsOK) {
                String result = createLabel(label);
                System.debug('Creazione della label ' + label.Name + ': '+ result);
            }
        }
        if (labelsKO.size() > 0) {
            System.debug('Le seguenti ' + labelsKO.size() + 'label non sono state create:');
            for (LabelWrapper label : labelsKO) {
                System.debug(label.Name + ' - ' + label.MasterLabel + ' - ' + label.Value);
            }
        }
    }

    // This is used to mass a single label from a LabelWrapper
    public static String createLabel(LabelWrapper label) {
        if (label.Language == null) {
            label.Language = 'en_US';
        }
        if (label.MasterLabel == null) {
            label.MasterLabel = label.Name;
        }
        if (label.isProtected == null) {
            label.isProtected = 'false';
        }

        // Replace whitespaces
        if (label.MasterLabel.contains(' ')) {
            label.MasterLabel = label.MasterLabel.replace(' ', '_');
        }
    // Create a Http request with post method
        HttpRequest req = new HttpRequest();
        String labelStr = '{"Name":"' + label.Name + '","MasterLabel":"' + label.MasterLabel + '","Value":"' + label.Value + '","isProtected":"' + label.isProtected + '","Language":"' + label.Language + '","Category":"' + label.Category + '"}';
        // System.debug('Label string: ' + labelStr);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        // getSalesforceBaseUrl is deprecated from api 58
        // req.setEndpoint(Url.getSalesforceBaseUrl().toExternalForm()+'/services/data/v56.0/tooling/sobjects/ExternalString');
        req.setEndpoint(Url.getOrgDomainUrl().toExternalForm()+'/services/data/v56.0/tooling/sobjects/ExternalString');
        req.setMethod('POST');
        req.setBody(labelStr);

        // send request and receive response
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201){
            return 'OK';
        } else {
            return 'KO (' + res.getStatusCode() + ' ' + res.getStatus() + ' | ' +  res.getBody() + ')';
        }
     }


    // Metodo usato per creare una label al volo.
    // Usage: MassLabelTool.createSingleLabel('TestLabel', 'TestValue', 'TestCategory', null);
    // @param labelName: nome della label (spazi ammessi)
    // @param developerName: nome API della label (Spazi non ammessi, vengono sostituiti dagli anderscore, se null è uguale al nome della label)
    // @param labelValue: valore della label
    // @param labelCategory: categoria della label (può essere null)
    // @param language: lingua della label (se null è uguale a en_US)
    // @param isProtected: se true la label è protetta (se null è uguale a false, il default)
    public static void createSingleLabel(String labelName, String developerName, String labelValue, String labelCategory, String language, Boolean isProtected) {
        if (language == null) {
            language = 'en_US';
        }

        if (isProtected == null) {
            isProtected = false;
        }
        String isProtectedStr = isProtected ? 'true' : 'false';

        // Replace whitespaces
        if (labelName.contains(' ')) {
            labelName = labelName.replace(' ', '_');
        }
        if (developerName == null) {
            developerName = labelName;
        }

        if (developerName.contains(' ')) {
            developerName = developerName.replace(' ', '_');
        }
        // Create a Http request with post method
        HttpRequest req = new HttpRequest();
        String labelStr = '{"Name":"' + labelName + '","MasterLabel":"' + developerName + '","Value":"' + labelValue + '","isProtected":"' + isProtectedStr + '","Language":"' + language + '","Category":"' + labelCategory + '"}';

        // System.debug('Label string: ' + labelStr);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        // getSalesforceBaseUrl is deprecated from api 58
        // req.setEndpoint(Url.getSalesforceBaseUrl().toExternalForm()+'/services/data/v56.0/tooling/sobjects/ExternalString');
        req.setEndpoint(Url.getOrgDomainUrl().toExternalForm()+'/services/data/v56.0/tooling/sobjects/ExternalString');
        req.setMethod('POST');
        req.setBody(labelStr);

        // send request and receive response
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201){
            System.debug('Label creata con successo: ' + developerName + ' (' + labelValue +')');
        } else {
            System.debug('Qualcosa è andato storto!\n (' +  res.getBody() + ')');
        }
    }

    public class LabelWrapper {
        public String Name;
        public String MasterLabel;
        public String Value;
        public String isProtected;
        public String Language;
        public String Category;
    }
}
