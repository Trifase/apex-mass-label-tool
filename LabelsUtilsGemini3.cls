public class LabelUtils {
/*

// 1. Define the Labels (Name;Category;Value)
String textblock = 
    'ManageSA_Title_Main;ManageSA;Manage SA Trackings\n' +
    'ManageSA_Title_RelatedTracking;ManageSA;Related Apply SA Tracking\n' +
    'ManageSA_Btn_CreateDeal;ManageSA;Create SO business Deal\n';

// 2. Parse CSV
List<LabelUtils.LabelWrapper> labelList = LabelUtils.makeLabelListfromCSV(textblock);

// 3. Create Labels (This performs the Callouts)
LabelUtils.createLabels(labelList);
*/



    // Wrapper to hold label data
    public class LabelWrapper {
        public String Name;         // API Name (No spaces)
        public String MasterLabel;  // UI Label (Spaces allowed)
        public String Value;        // The text content
        public String Category;
        public String Language;
        public Boolean isProtected;

        public LabelWrapper() {
            this.Language = 'en_US';
            this.isProtected = false;
        }
    }

    /**
     * Parses the text block into a list of wrappers.
     * Expected format: Name;Category;Value
     */
    public static List<LabelWrapper> makeLabelListfromCSV(String textblock) {
        List<LabelWrapper> labels = new List<LabelWrapper>();
        
        // Split by new line (handle both Windows \r\n and Unix \n)
        List<String> lines = textblock.replaceAll('\r\n', '\n').split('\n');

        for (String line : lines) {
            if (String.isBlank(line)) continue; // Skip empty lines

            List<String> fields = line.split(';');
            if (fields.size() < 3) continue; // Skip invalid lines

            LabelWrapper label = new LabelWrapper();
            label.Name = fields[0].trim();
            // Default MasterLabel to Name, replacing underscores with spaces for readability if desired
            // Or keep it same as Name. Here we default to Name.
            label.MasterLabel = fields[0].trim(); 
            label.Category = fields[1].trim();
            label.Value = fields[2].trim();
            
            labels.add(label);
        }
        return labels;
    }

    /**
     * Iterates through the list and creates labels via Tooling API.
     */
    public static void createLabels(List<LabelWrapper> labels) {
        if (labels.size() > 99) {
            System.debug(LoggingLevel.ERROR, '⚠️ SAFETY WARNING: You are trying to create ' + labels.size() + ' labels. Salesforce limits to 100 callouts per transaction. Split your batch.');
            return;
        }

        List<String> successes = new List<String>();
        List<String> failures = new List<String>();

        for (LabelWrapper label : labels) {
            boolean success = createLabelCallout(label);
            if (success) {
                successes.add(label.Name);
            } else {
                failures.add(label.Name);
            }
        }

        System.debug('=== PROCESS COMPLETE ===');
        System.debug('✅ Success (' + successes.size() + '): ' + successes);
        if (!failures.isEmpty()) {
            System.debug('❌ Failures (' + failures.size() + '): ' + failures);
        }
    }

    /**
     * Performs the single HTTP callout to create the ExternalString
     */
    private static Boolean createLabelCallout(LabelWrapper label) {
        // Prepare the map for JSON serialization (Handles quotes/escaping automatically)
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('Name', label.Name);
        jsonMap.put('MasterLabel', label.MasterLabel);
        jsonMap.put('Value', label.Value);
        jsonMap.put('Language', label.Language);
        jsonMap.put('Category', label.Category);
        jsonMap.put('isProtected', label.isProtected);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/sobjects/ExternalString');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(jsonMap)); // Using native serialization is much safer

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
                return true;
            } else {
                // If it fails, usually it's because the label already exists
                System.debug(LoggingLevel.ERROR, 'Failed: ' + label.Name + ' | ' + res.getBody());
                return false;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception: ' + e.getMessage());
            return false;
        }
    }
}
