global class UtilsGetSessionId{
    global static String getSessionIdFromVFPage(PageReference visualforcePage){
        String content = Test.isRunningTest() ? 'Start_Of_Session_Id testtesttest End_Of_Session_Id' : visualforcePage.getContent().toString();
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                e = content.indexOf('End_Of_Session_Id');
        return content.substring(s, e);
    }
}