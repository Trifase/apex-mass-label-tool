# apex-mass-label-tool
### A little class used to mass create labels using the Tooling API. 
It should work even in Anonymous Apex.

---
This tiny tool can be used in a couple of ways.

## Single label (direct)
```
MassLabelTool.createSingleLabel('Label Name', 'Label_API_Name', 'Text value of the label', 'Category', 'en_US', False);
```
The last parameter is a boolean for protected labels. Default False.

## Single label (Object)
Alternatively, you can pass a `LabelWrapper` object like this:
```
MassLabelWrapper.LabelWrapper label = new MassLabelWrapper.LabelWrapper();
label.Name = 'Label Name;
label.MasterLabel = 'Label_API_Name';
label.Value = 'Text value of the label';
label.isProtected = 'false';
label.Language = 'en_US';
label.Category = 'Category';
```
and pass `label` to `MassLabelTool.createLabel()` that returns 'OK' or 'KO' as a string:
```
String result = MassLabelTool.createLabel(label);
System.debug(result);
>DEBUG|OK
```
            
## Mass Creation
If you really want to create more than one label, you can do the following:

1. Create a String textblock that looks like a CSV, without the headers: `api_name;category;value`
```
String textblock = 'Label1;category;Label Value 1\n' +
                   'Label2;category;Label Value 2\n' +
                   'Label3;category;Label Value 3\n' +
                   'Label4;category;Label Value 4\n';
```
2. Pass the textblock to a self-explainatory `makeLabelListfromCSV()` function, that conveniently returns a `List` of `MassLabelWrapper.LabelWrapper`
```
List<MassLabelTool.LabelWrapper> labels = MassLabelTool.makeLabelListfromCSV(textblock);
```
3. Pass the labels list to `createLabels()`:
```  
MassLabelTool.createLabels(labels);
```
4. Enjoy!
```
21:25:51.51 (246990354)|USER_DEBUG|[64]|DEBUG|Creazione della label Label1: OK
21:25:51.51 (340706397)|USER_DEBUG|[64]|DEBUG|Creazione della label Label2: OK
21:25:51.51 (429309684)|USER_DEBUG|[64]|DEBUG|Creazione della label Label3: OK
21:25:51.51 (523438404)|USER_DEBUG|[64]|DEBUG|Creazione della label Label4: OK
```
Should (when) something go wrong, the debug should contain enough information to get you going.

Happy labeling I guess!
