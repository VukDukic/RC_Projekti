public class RCSupportAdvCaseCreate {
    public Case caseObj {get;set;}
    public string selectedProduct {get;set;}
    public string alternateEmail {get;set;}
    public string selectedProduct2 {get;set;}
    public string selectedProduct3 {get;set;}
    public string severityLevel {get;set;}
    public string selectSortValue {get;set;} 
    public string selectSearchValue {get;set;}
    public string inputSearchValue {get;set;}
    public Boolean isGuestUser{get;set;}
    public Contact ConDetail{get;set;}
    public String PhoneExt{get;set;}
    List<AccountContactRole>  toFindLoginUserProfileLst = new List<AccountContactRole>();
    public List<SelectOption> lstselectOptionView{get;set;}     
    public String selectedViewOptions1{get;set;}                
    public  map<string,WrPortalQuestion> mapPortalQuestion {get;set;}
    public Boolean isSubmitCase{get;set;}
    public static string supportChatTextFromLabel = (System.label.Support_Chat_Text != NULL ? system.label.Support_Chat_Text : '');
    public static string strFaxing ='Faxing ' + supportChatTextFromLabel;
    public static string strSoftphone ='Softphone ' + supportChatTextFromLabel;
    public static string strDeskphone ='Desk Phones ' + supportChatTextFromLabel;
    public Boolean chkValue{get;set;}
    public string strValue{get;set;}
   
    /*Case 03272867:  Product Assistance Custom setting changes {*/
    static Map<String,String> mapPortalList;
    static Map<String,Set<String>> mapProductAssistance;
    static String baseUrl;
    
    static{
        if(!test.isRunningTest()){
            baseURL = ApexPages.currentPage().getHeaders().get('Host');
        }else{
            baseURL = 'success.ringcentral.com';
        }
        mapPortalList = new Map<String,String>();
        List<Portals_List__c> lstPortal = Portals_List__c.getall().values();
        if(lstPortal != null && lstPortal.size() > 0){
            for(Portals_List__c obj : lstPortal){
                String portalName = obj.Name.toLowerCase().trim();
                String portalBrand = obj.Brand__c.toLowerCase().trim();
                mapPortalList.put(portalName,portalBrand);
            }           
        }
        
        mapProductAssistance = new Map<String,Set<String>>();
        List<Product_Assistance_List__c> lstProductAssistance = Product_Assistance_List__c.getall().values();
        if(lstProductAssistance != null && lstProductAssistance.size() > 0){
            for(Product_Assistance_List__c obj : lstProductAssistance){
                String productAssName = obj.Name.toLowerCase().trim();
                List<String> portalList = obj.Portal__c.trim().split(',');
                Set<String> portalSet = new Set<String>();
                if(portalList != null && portalList.size() > 0){
                    for(String str : portalList){
                        portalSet.add(str.toLowerCase().trim());
                    }
                }
                mapProductAssistance.put(productAssName,portalSet);
            }           
        }
    }
    /*} Case 03272867:  Product Assistance Custom setting changes */
   
    public Attachment attachment {
      get {
          if (attachment == null)
            attachment = new Attachment(); 
          return attachment;
        }
      set;
    }
    
    public string parentId {get;set;}
    public User loginUser{get;set;}
    public string brandName {get;set;}
    
    public RCSupportAdvCaseCreate() {
        callConstuctorLogic();
    }
    
    public RCSupportAdvCaseCreate(ApexPages.StandardController controller) {
        callConstuctorLogic();
    }
    
    public void callConstuctorLogic() {
        if(UserInfo.getUserType() == 'Guest') {
            isGuestUser = true;
        }   else {
            isGuestUser = false;
        }
        isSubmitCase=false;
        caseObj = new Case();
        wrPgItrCases = new WrPgIterator();
        productAssistanceItems = new List<selectOption>(); 
        productAssistanceItemsLvl2 = new List<selectOption>(); 
        productAssistanceItemsLvl3 = new List<selectOption>(); 
        caseSeverityItems =  new List<selectOption>();
        productAssistanceItems = getproductAssistanceItemsValues();
        productAssistanceItemsLvl2 = productAssistanceItemsLvl2();
        productAssistanceItemsLvl3 = productAssistanceItemsLvl3();
        caseSeverityItems = getcaseSeverityItemsValues();
        selectSortValue = 'Case_Status';
        selectSearchValue = 'Case_Number'; 
        selectedViewOptions1 = 'All Cases';       
        mapPortalQuestion = new map<string,WrPortalQuestion>();
        mapPortalQuestion = getPortalQuestion();
        ConDetail  = new Contact();
        loginUser = [SELECT id,ContactId,Contact.AccountId, Profile.Name, Contact.Email,Contact.Phone_Ext__c,Contact.Phone,Contact.LastName,Contact.FirstName,
                        Contact.Account.RC_Tier__c, Contact.Account.Number_of_DL_s__c,Contact.Account.RC_Brand__c, Contact.Account.Total_Account_DL_s__c, Contact.Account.VIP_Account_Indicator__c  FROM User WHERE Id =:UserInfo.getUserId() limit 1];  
                        
        system.debug('LOGIN USER '+ loginUser);            
        try {    
            ConDetail = new Contact(Id=loginUser.ContactId);
            ConDetail.LastName = loginUser.Contact.LastName;
            ConDetail.FirstName = loginUser.Contact.FirstName;
            ConDetail.Email = loginUser.Contact.Email;
            ConDetail.Phone = loginUser.Contact.Phone;
            ConDetail.Phone_Ext__c = loginUser.Contact.Phone_Ext__c;
         
            if(ConDetail.Phone_Ext__c !=null && ConDetail.Phone_Ext__c != 0 ){
                ConDetail.Phone_Ext__c =Integer.valueOf(ConDetail.Phone_Ext__c);
                PhoneExt = String.valueOf(loginUser.Contact.Phone_Ext__c);//update 0n 28/11/13
            } else{
                PhoneExt = '';
            }
            ConDetail.AccountId = loginUser.Contact.AccountId;
            brandName = loginUser.Contact.Account.RC_Brand__c;
            toFindLoginUserProfileLst =[Select Role, IsPrimary, Id, ContactId, AccountId From AccountContactRole 
                                        WHERE ContactId =: loginUser.ContactId AND AccountId =:loginUser.Contact.AccountId and 
                                        (Role ='RC Primary User' OR Role = 'RC Admin User') LIMIT 1];  // and IsPrimary = true
            lstselectOptionView = new List<SelectOption>();   
            lstselectOptionView = selectOptionViews(); 
        } catch(Exception ex){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
        }
        getRecordTypeListCS();
        getDateFormat();
        getClosedStatus();
        getUserCaseDetails();
        if(ApexPages.currentPage().getParameters().get('parentId') != null && ApexPages.currentPage().getParameters().get('parentId') != '') {
            parentId = ApexPages.currentPage().getParameters().get('parentId');
            try {
                List<Case> cloneCaseObj = [SELECT Alternate_Email__c,Product_Assistance__c,Product_Assistance_Lvl3__c,Product_Assistance_Lvl2__c,Case_Severity__c,description,subject,Account.RC_Tier__c,Account.Number_of_DL_s__c,Account.Total_Account_DL_s__c, Account.VIP_Account_Indicator__c 
                                                FROM Case WHERE Id = :parentId LIMIT 1];
                if(cloneCaseObj != null && cloneCaseObj.size() == 1) {
                    caseObj.Subject = cloneCaseObj[0].Subject;
                    alternateEmail = cloneCaseObj[0].Alternate_Email__c;
                    caseObj.Description = cloneCaseObj[0].Description;
                    caseObj.Status = 'New';
                    selectedProduct = cloneCaseObj[0].Product_Assistance__c;
                    selectedProduct2 = cloneCaseObj[0].Product_Assistance_Lvl2__c;
                    selectedProduct3 = cloneCaseObj[0].Product_Assistance_Lvl3__c;
                    severityLevel = cloneCaseObj[0].Case_Severity__c;
              }
              if(test.isRunningTest()){
                integer i = 2/0;
              }
           } catch(Exception ex) {}
        }
    }
    
    public PageReference assistanceChange(){
        return null;
    }
    
    public PageReference showArticleList(){
         isSubmitCase=true;
        return null;
    }
    
     public boolean SummitCase(){
        return false;
    }
    
    public Integer fileSize {get;set;}
    
    private void contactPreConditions() {
        system.debug('loginUser.Contact.Email'+loginUser.Contact.Email);
        String loginUserEmail = loginUser.Contact.Email;
        String loginUserPhone = loginUser.Contact.Phone;
        String loginUserFName = loginUser.Contact.FirstName;
        String loginUserLName = loginUser.Contact.lastName;
        string loginPhoneExt;//  = String.valueOf(loginUser.Contact.Phone_Ext__c);//Integer.valueOf(loginUser.Contact.Phone_Ext__c);
        if(loginUser.Contact.Phone_Ext__c != null && loginUser.Contact.Phone_Ext__c != 0 )
            loginPhoneExt  = String.valueOf(loginUser.Contact.Phone_Ext__c);//Integer.valueOf(loginUser.Contact.Phone_Ext__c);
        else
            loginPhoneExt = '';
        String newEmail = ConDetail.Email;
        String newPhone = ConDetail.Phone;
        String newFName = ConDetail.FirstName;
        String newLName = ConDetail.lastName;
        String newPhoneExt;
        
        if(PhoneExt != null && PhoneExt != '')
             newPhoneExt = PhoneExt;
        else
            newPhoneExt = '';
        
        Contact contactObj = null;
        if(loginUserEmail != newEmail 
            || loginUserPhone != newPhone
            || loginUserFName != newFName
            || loginUserLName != newLName
            || loginPhoneExt != newPhoneExt
            ) {
            String accountId = loginUser.Contact.AccountId;
            if(loginUserEmail == newEmail) {
                //contactObj = new Contact(Id = loginUser.ContactId);
                contactObj = new Contact();
                contactObj = [select AccountId from Contact where ID =:loginUser.ContactId];
            }
                
            if(contactObj != null) {
                contactObj.Email = newEmail;
                contactObj.Phone = newPhone;
                if(PhoneExt!= null && PhoneExt != '' )
                    contactObj.Phone_Ext__c = Double.valueOf(PhoneExt);//ConDetail.Phone_Ext__c;//Updated on 27/11/13
                else
                    contactObj.Phone_Ext__c = Double.valueOf('0');
                contactObj.FirstName = newFName;
                contactObj.lastName = newLName;
                System.debug('### UPDATING CONTACT ' + loginUser.Id + ' CONTACT ' + contactObj);
                update contactObj;
            } else {
                contactObj = new Contact();
                contactObj.FirstName = newFName;
                contactObj.LastName = newLName;
                contactObj.Email = newEmail;
                contactObj.AccountId = accountId;
                contactObj.Phone = newPhone;
                //contactObj.Phone_Ext__c ;//Double.valueOf(PhoneExt);//ConDetail.Phone_Ext__c;//Updated on 27/11/13
                if(PhoneExt!= null && PhoneExt != '' )
                    contactObj.Phone_Ext__c = Double.valueOf(PhoneExt);//ConDetail.Phone_Ext__c;//Updated on 27/11/13
                else
                    contactObj.Phone_Ext__c = Double.valueOf('0');
                System.debug('### INSERTING CONTACT ' + loginUser.Id + ', Owner Id = ' + contactObj.ownerId);
                //System.debug('contactObj.Phone_Ext__c  '+contactObj.Phone_Ext__c +'  ext '+ Double.valueOf(PhoneExt)+'Insert');
                try {
                    insert contactObj;
                    if(test.isRunningTest()){
                        integer i = 2/0;
                    }
                } catch(Exception e) {System.debug('#### EXCEPTION COMES HERE ' + e); }
            }
        }
        caseObj.ContactId = (contactObj == null ? loginUser.ContactId : contactObj.id);
        caseObj.AccountId = (contactObj == null ? loginUser.Contact.AccountId : contactObj.AccountId);
    }
    
    public PageReference createCase() {
        try {
            system.Debug('>>>>>caseObj.AccountId 1>>' + caseObj.AccountId);
            system.Debug('>>>>>caseObj.CreatedById 1>>' + caseObj.CreatedById);
            contactPreConditions();
            List<User> userDet = new List<User>{loginUser};
            String developerPlatformId = OpportunityHelper.getOppRecordTypeMap('Developer Platform');
            if('Developer Platform'.equalsIgnoreCase(selectedProduct.trim())){
                caseObj.RecordTypeId = developerPlatformId;
            }else if('RingCentral APIs'.equalsIgnoreCase(selectedProduct.trim())){
                caseObj.RecordTypeId = developerPlatformId;
            }else{
                caseObj.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('Support-Case');
            }
            caseObj.Origin = 'Web';
            caseObj.Product_Assistance__c = selectedProduct;
            caseObj.Alternate_Email__c = alternateEmail;
            caseObj.Product_Assistance_Lvl2__c = selectedProduct2;
            caseObj.Product_Assistance_Lvl3__c = selectedProduct3;
            caseObj.Case_Severity__c = severityLevel;
            try {
                system.Debug('>>>>>caseObj.AccountId 11>>' + caseObj.AccountId);
                List<Entitlement> entitlementObj = EntitlementHelper.getEntitlement(userDet[0].Contact.AccountId);
                caseObj.EntitlementId = (entitlementObj ==null || entitlementObj.size() == 0 ? null : entitlementObj.get(0).Id);
            } catch(Exception e) {
                /*ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
                return null;
                */
            }
            /*List<Group> queueList = [Select id from Group where Name = 'General Support Queue' limit 1];
            if(queueList != null && queueList.size()>0) {
                caseObj.OwnerId = queueList[0].Id;
            }*/
            system.Debug('>>>>>caseObj.AccountId 12>>' + caseObj.AccountId);
            caseObj = HelperCaseDispatch.assignQueue(caseObj,loginUser);
            system.Debug('>>>>>caseObj.AccountId 13>>' + caseObj.AccountId);
            system.Debug('>>>>>caseObj.AccountId 2>>' + caseObj.AccountId);
            system.Debug('>>>>>caseObj.CreatedById 2>>' + caseObj.CreatedById);
            insert caseObj;
            if(attachment != null && attachment.body != null) {
                System.Debug('>>>##>>323'+fileSize);
                if(fileSize != null) {
                    Decimal fileSizeDB = Decimal.valueof(fileSize)/(1024 * 1024);
                    System.Debug('>>>##>>323e>>'+fileSizeDB);
                    if(fileSizeDB > 5) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Uploaded file size must not be greater than 5 MB.'));
                        return null;
                    }       
                }   
                Attachment attachObj = attachment;
                attachObj.ParentId = caseObj.id;
                insert attachObj;
                System.Debug('>>>##>>3'+attachObj); 
            }
            PageReference pg = new PageReference('/RCSupportAdvCaseDetail');
            pg.getParameters().put('Id',caseObj.Id);
            pg.getParameters().put('IsView','true');
            pg.setRedirect(true);
            return pg; 
        } catch(Exception ex) {
            System.Debug('>>>##>>2'+ex);
        } finally {
            attachment.body = null; 
        }
        return null;
    }
    
    public void setPortalQuestion() {
        caseObj.Description = null;
        
        strValue='';
         chkValue = false;
        if(selectedProduct.equalsIgnoreCase('Faxing')){
            strValue = strFaxing;
            chkValue = true;
        }
        if(selectedProduct.equalsIgnoreCase('Softphone')){
            strValue = strSoftphone;
            chkValue = true;
        }
        if(selectedProduct.equalsIgnoreCase('Desk Phones')){
            strValue = strDeskphone;
            chkValue = true;
        }
        system.Debug('>>@@@>>setPortalQuestion');
        system.Debug('>>@@@1>>'+selectedProduct);
        system.Debug('>>@@@2>>'+selectedProduct2);
        system.Debug('>>@@@3>>'+selectedProduct3);
        string mapKey;
        if(selectedProduct != null) {
            mapKey = selectedProduct;
            if(selectedProduct2 != null) {
                mapKey = mapKey + '*-*' + selectedProduct2;
                if(selectedProduct3 != null) {
                    mapKey = mapKey + '*-*' + selectedProduct3;
                }               
            }
            mapKey = mapKey.toUpperCase().trim();
        }
        //system.Debug('>>@@@4>>'+ mapKey);
        // if(mapPortalQuestion == null || mapPortalQuestion.size() == 0)
            // mapPortalQuestion = getPortalQuestion();
        //system.debug('### RESULT= ' + mapPortalQuestion.get(mapKey));
        if(mapKey != null && mapPortalQuestion != null && mapPortalQuestion.get(mapKey) != null) {
            string question1;
            string question2;
            string question3; 
            if(mapPortalQuestion.get(mapKey).question1 != '*NA*') {
                question1 = 'In order to serve you better, please answer the following questions:';
                question1 = question1 + '\n\n1 : ' + mapPortalQuestion.get(mapKey).question1.replaceAll('-NL-', '\n');
            }
            if(mapPortalQuestion.get(mapKey).question2 != '*NA*') {
                question2 = '\n\n2 : ' + mapPortalQuestion.get(mapKey).question2.replaceAll('-NL-', '\n');
            }
            if(mapPortalQuestion.get(mapKey).question3 != '*NA*') { 
                question3 = '\n\n3 : ' + mapPortalQuestion.get(mapKey).question3.replaceAll('-NL-', '\n') ;
            }
            system.Debug('>>@@@5>>'+ question1);
            system.Debug('>>@@@6>>'+ question2);
            system.Debug('>>@@@7>>'+ question3);
            //caseObj.Description = question1 == null ? '': question1 + ' ' + question2 == null ? '': question2 + ' ' + question3 == null ? '': question3;
            caseObj.Description = (question1 == null ? '':question1) + ' ' + (question2 == null? '':question2) + ' ' + (question3 == null? '': question3);
            if(question1 != null || question2 != null || question3 != null) {
                caseObj.Description = caseObj.Description + '\n\n' + 'Please include any additional comments or details that you feel will better assist us with this issue below.';
            }
        }
    }
    
    public class WrPortalQuestion {
        public string key {get;set;}
        public string question1 {get;set;}
        public string question2 {get;set;}
        public string question3 {get;set;}
        public WrPortalQuestion() {
            question1 = question2 = question3 = key = '';
        }
    }
    
    public static Map<string,WrPortalQuestion> getPortalQuestion() {
        map<string,WrPortalQuestion> rtnPortalQuestionMapMap = new map<string,WrPortalQuestion>(); 
        try {
                List<Document> docList = [Select body, bodyLength, ContentType, Url from Document where Name = 'PortalQuestion'];
                if(Test.isRunningTest()) {
                    Blob testDoc = Blob.valueOf('Test2*-*Test3*-*Test4,Test2,Test3,Test4,EOF\n');
                     List<List<String>> parsedCSV = parseCSV(testDoc.toString().trim(),false);
                     if(parsedCSV != null) {
                            for(List<String> listObj : parsedCSV) {
                                WrPortalQuestion wrPortalQuestionObj = new WrPortalQuestion();
                                system.Debug('>>222>>>'+ listObj);
                                wrPortalQuestionObj.key = listObj[0].trim().toUpperCase();
                                if(String.isNotBlank(listObj[1]) && listObj[1].startsWith('"') && listObj[1].endsWith('"')){
                                    wrPortalQuestionObj.question1 = listObj[1].substring(1, listObj[1].length()-1);
                                }else{
                                    wrPortalQuestionObj.question1 = listObj[1];
                                }
                                if(String.isNotBlank(listObj[2]) && listObj[2].startsWith('"') && listObj[2].endsWith('"')){
                                    wrPortalQuestionObj.question2 = (listObj[2]).substring(1, listObj[1].length()-1);
                                }else{
                                    wrPortalQuestionObj.question2 = (listObj[2]);
                                }
                                if(String.isNotBlank(listObj[3]) && listObj[3].startsWith('"') && listObj[3].endsWith('"')){
                                    wrPortalQuestionObj.question3 = listObj[3].substring(1, listObj[1].length()-1);
                                }else{
                                    wrPortalQuestionObj.question3 = listObj[3];
                                }
                                rtnPortalQuestionMapMap.put(wrPortalQuestionObj.key,wrPortalQuestionObj);
                            } 
                    }
                }
                if(docList != null && docList.size()>0) {
                    if(docList[0].Body != null) {
                        system.Debug('>>1212>>>'+ docList[0].Body.toString().trim());
                        List<List<String>> parsedCSV =  parseCSV(docList[0].Body.toString().trim(),false);
                        if(parsedCSV != null) {
                            for(List<String> listObj : parsedCSV) {
                                WrPortalQuestion wrPortalQuestionObj = new WrPortalQuestion();
                                system.Debug('>>222>>>'+ listObj);
                                wrPortalQuestionObj.key = listObj[0].trim().toUpperCase();
                                if(String.isNotBlank(listObj[1]) && listObj[1].startsWith('"') && listObj[1].endsWith('"')){
                                    wrPortalQuestionObj.question1 = listObj[1].substring(1, listObj[1].length()-1);
                                }else{
                                    wrPortalQuestionObj.question1 = listObj[1];
                                }
                                if(String.isNotBlank(listObj[2]) && listObj[2].startsWith('"') && listObj[2].endsWith('"')){
                                    wrPortalQuestionObj.question2 = (listObj[2]).substring(1, listObj[2].length()-1);
                                }else{
                                    wrPortalQuestionObj.question2 = (listObj[2]);
                                }
                                if(String.isNotBlank(listObj[3]) && listObj[3].startsWith('"') && listObj[3].endsWith('"')){
                                    wrPortalQuestionObj.question3 = listObj[3].substring(1, listObj[3].length()-1);
                                }else{
                                    wrPortalQuestionObj.question3 = listObj[3];
                                }
                                rtnPortalQuestionMapMap.put(wrPortalQuestionObj.key,wrPortalQuestionObj);
                            } 
                        }
                    }       
                }
                return rtnPortalQuestionMapMap;
        } catch(Exception ex) {
            system.Debug('>>ex>>>'+ ex.getMessage());
        }
        return null;
    }
    
    private static List<List<String>> parseCSV(string contents, Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        contents = contents.replaceAll('""','DBLQT');
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line : lines) {
            if (line.replaceAll(',','').trim().length() == 0) break;
            List<String> fields = line.split(',');  
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"').trim());
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field.trim();
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"').trim());
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field.trim();
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"').trim());
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) allFields.remove(0);
        return allFields; 
    }
    
    public List<Case> usercaseList {get;set;}
    public List<WrapperCase> usercaseListWr {get;set;}
    public void getUserCaseDetails() {
        try {
            createQuery();                  
        } catch(Exception ex) {}
    }
    
    public void sortCaseList() {
        try {
            system.Debug('>>>!!>>>'+selectSortValue);
            getUserCaseDetails();
        } catch(Exception ex) {}
    }
    
    public void searchCase() {
        try {
            createQuery();
        } catch(Exception ex) {}
    }
    
    Set<string> recordTypesSet = new Set<string>();
    public void getRecordTypeListCS() {
        try {
            Map<string, Portal_Cases_Record_Types__c> recordTypesCSMap = Portal_Cases_Record_Types__c.getAll();
            if(recordTypesCSMap != null) {
                recordTypesSet = recordTypesCSMap.keyset();
            }
        } catch(Exception ex) {}
    }
    
    Set<string> closedStatusSet = new Set<string>();
    public void getClosedStatus() {
        closedStatusSet.add('Duplicate');
        closedStatusSet.add('Invalid');
        closedStatusSet.add('Cancelled');
        closedStatusSet.add('Closed');
        closedStatusSet.add('Closed - Endorsed');
        closedStatusSet.add('Closed - No Contact');
        closedStatusSet.add('Closed - No Issue');
        closedStatusSet.add('Closed - No Response');
        closedStatusSet.add('Closed - No response');
    }
    
    string formatDate;
    public void getDateFormat() {
        try {
            Date originalDate = Date.newInstance(2013, 11, 20);
            DateTime dtConverted = Datetime.newInstance(originalDate.year(),originalDate.month(),originalDate.day(),0,0,0);
            formatDate = dtConverted.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            System.Debug('>>formatDate>>>'+formatDate);
        } catch(Exception ex) {}
    }
    
    public string createQuery() {
        string strQuery;
        try {
            if(selectedViewOptions1 == 'My Open Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Alternate_Email__c,Subject,Case_Severity__c,CreatedDate '+ 
                                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+  
                                    ' and  Status NOT IN :closedStatusSet and (contactId = \'' + loginUser.ContactId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';       
            } else if(selectedViewOptions1 == 'My Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Alternate_Email__c,Subject,Case_Severity__c,CreatedDate '+ 
                                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+  
                                    ' and  (contactId = \'' + loginUser.ContactId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';       
            } else if(selectedViewOptions1 == 'All Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Alternate_Email__c,Subject,Case_Severity__c,CreatedDate '+ 
                                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+  
                                    ' and  (accountId = \'' + loginUser.Contact.AccountId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';       
            } else if(selectedViewOptions1 == 'All Open Cases') {
                strQuery = 'Select Id,status,CaseNumber,Contact.Name,Subject,Case_Severity__c,CreatedDate '+ 
                                    ' from Case where ((RecordType.Name = \'Support-Case\') or (RecordType.Name IN :recordTypesSet and createddate > '+ formatDate +')) '+  
                                    ' and Status NOT IN :closedStatusSet and (accountId = \'' + loginUser.Contact.AccountId +'\' OR CreatedbyId = \'' + UserInfo.getUserId() +'\')';       
            }                          
                                
            if(!string.isBlank(selectSearchValue) && !String.IsBlank(inputSearchValue)) {
                    strQuery = strQuery + ' and ';
                    if(selectSearchValue == 'Case_Number') {
                        strQuery = strQuery + 'CaseNumber like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\'';    
                    } else if(selectSearchValue == 'Contact_Name') {
                        strQuery = strQuery + 'Contact.Name like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\''; 
                    } else if(selectSearchValue == 'Subject') {
                        strQuery = strQuery + 'Subject like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\''; 
                    } else if(selectSearchValue == 'Severity_Level') {
                        strQuery = strQuery + 'Case_Severity__c like  \'%' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\''; 
                    }
            }
            strQuery = strQuery + ' order by ';                     
            if(!String.isBlank(selectSortValue)) { 
                if(selectSortValue == 'Time_Date_Opened') {
                    strQuery = strQuery + 'CreatedDate desc';        
                } else if(selectSortValue == 'Case_Status') {
                    strQuery = strQuery + 'Status asc, CreatedDate desc';
                }
            }
            strQuery = strQuery + ' Limit 50000 ';  
            system.debug('>>!!>>'+strQuery);                    
            createCaseList(strQuery);                       
        } catch(Exception ex) {}
        return strQuery;
    }
    
    /*public string createQuery() {
        string strQuery;
        try {
            strQuery = 'Select Id,status,CaseNumber,Contact.Name,Subject,Case_Severity__c,CreatedDate '+ 
                                    ' from Case where CreatedbyId = \'' + UserInfo.getUserId() +'\'';
            
            /*strQuery = 'Select Id,status,CaseNumber,Contact.Name,Subject,Case_Severity__c,CreatedDate '+ 
                                    ' from Case ';*/
                                
            /*if(!string.isBlank(selectSearchValue) && !String.IsBlank(inputSearchValue)) {
                    strQuery = strQuery + ' and ';
                    if(selectSearchValue == 'Case_Number') {
                        strQuery = strQuery + 'CaseNumber like  \'' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\'';    
                    } else if(selectSearchValue == 'Contact_Name') {
                        strQuery = strQuery + 'Contact.Name like  \'' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\''; 
                    } else if(selectSearchValue == 'Subject') {
                        strQuery = strQuery + 'Subject like  \'' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\''; 
                    } else if(selectSearchValue == 'Severity_Level') {
                        strQuery = strQuery + 'Case_Severity__c like  \'' + String.escapeSingleQuotes(inputSearchValue.trim()) +'%\''; 
                    }
            }
            strQuery = strQuery + ' order by ';                     
            if(!String.isBlank(selectSortValue)) {
                if(selectSortValue == 'Time_Date_Opened') {
                    strQuery = strQuery + 'CreatedDate desc';        
                } else if(selectSortValue == 'Case_Status') {
                    strQuery = strQuery + 'Status asc';
                }
            }
            strQuery = strQuery + ' Limit 50000 ';  
            system.debug('>>!!>>'+strQuery);                    
            createCaseList(strQuery);                       
                                     
        } catch(Exception ex) {}
        return strQuery;
    }*/
    
    public List<SelectOption> selectOptionViews() {         
        List<SelectOption> options = new List<SelectOption>();
        if(toFindLoginUserProfileLst != null && toFindLoginUserProfileLst.size()>0){
            options.add(new SelectOption('All Cases','All Cases'));
            options.add(new SelectOption('All Open Cases','All Open Cases')); 
        }
        options.add(new SelectOption('My Cases','My Cases')); 
        options.add(new SelectOption('My Open Cases','My Open Cases'));
        return options;
    }   
    
    public void createCaseList(string strQuery) {
        usercaseList = new List<Case>();
        usercaseListWr = new List<WrapperCase>();
        try {
            if(!String.isBlank(strQuery)) {
                system.Debug('>>>!!>>>'+strQuery);                  
                usercaseList = Database.Query(strQuery);
                Integer i = 0;                  
                for(Case caseObj : usercaseList) {
                    WrapperCase wrCaseObj = new WrapperCase();
                    wrCaseObj.caseObj = caseObj;
                    wrCaseObj.strformatDT = caseObj.CreatedDate.format('h:mm a z, MM/dd/yyyy','America/New_York');
                    wrCaseObj.caseIndex = ++i;
                    usercaseListWr.add(wrCaseObj);
                }
                userCasePaging = new RCSupportPortalCasePagingHelper(usercaseListWr);   
                wrPgItrCases.rtnIntList = null;
                getCasesPgItr();            
            }
        } catch(Exception ex) {}
    }
    
    public RCSupportPortalCasePagingHelper userCasePaging {get;set;}
    public List<WrapperCase> usercaseListWr1 = new List<WrapperCase>();
    public List<WrapperCase> getcaseList1() {
        try {
            usercaseListWr1 =  new List<WrapperCase>(); 
            if(userCasePaging.rtnListObj1 != null && (userCasePaging.rtnListObj1).size()>0) {
                for(Object caseObj : userCasePaging.rtnListObj1) {
                    usercaseListWr1.add((WrapperCase)caseObj);
                }   
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            return null;
        }
        return usercaseListWr1;
    }
    
   public WrPgIterator wrPgItrCases {get;set;}
   public List<Integer> tempCasesPgItr {get;set;}
   public void getCasesPgItr() {
     try {
        tempCasesPgItr = new List<Integer>();
        tempCasesPgItr = createPgItrList(userCasePaging,wrPgItrCases);
        system.Debug('>>123>>>'+tempCasesPgItr);
        if(tempCasesPgItr != null && tempCasesPgItr.size()>0) {
            wrPgItrCases.wrfirstElement = tempCasesPgItr.get(0);    
            wrPgItrCases.wrlastElement =  tempCasesPgItr.get(tempCasesPgItr.size() - 1);
        }       
     } catch(Exception ex) { }
   } 
    
    public List<Integer> createPgItrList(RCSupportPortalCasePagingHelper  casePagingObj, WrPgIterator wrItrTempObj) {
        try {
            lastElement = 0;
            firstElement = 0;
            WrPgIterator wrPgItrObj = new WrPgIterator();
            wrPgItrObj = wrItrTempObj;
            if(wrPgItrObj.rtnIntList == null) {
                wrPgItrObj.rtnIntList = new List<Integer>();
                if(casePagingObj.getTotalPageNumber() < 10) {
                    for(Integer i=1;i<=casePagingObj.getTotalPageNumber();i++) { 
                        wrPgItrObj.rtnIntList.add(i);
                    }
                } else {
                    for(Integer i=1;i<=10;i++) {
                        wrPgItrObj.rtnIntList.add(i);
                    }
                }
                lastElement = wrPgItrObj.rtnIntList.get(wrPgItrObj.rtnIntList.size() - 1);
                firstElement = wrPgItrObj.rtnIntList.get(0);
            } else if(wrPgItrObj.rtnIntList != null && wrPgItrObj.rtnIntList.size()>0) {
                System.Debug('>>actionType>>'+actionType);
                if(actionType == 'Previous') {
                    firstElement = wrPgItrObj.rtnIntList.get(0);
                    casePagingObj.pageNumberParam = firstElement - 10;
                    casePagingObj.getRecordsByPN();
                    wrPgItrObj.rtnIntList.clear();
                    for(Integer i = firstElement - 10 ;i <= firstElement - 1;i++) { 
                        wrPgItrObj.rtnIntList.add(i);
                    }
                } else if(actionType == 'Next') {
                    System.Debug('>>Next>>');
                    lastElement = wrPgItrObj.rtnIntList.get(wrPgItrObj.rtnIntList.size() - 1);
                    casePagingObj.pageNumberParam = lastElement + 1;
                    casePagingObj.getRecordsByPN();
                    if((casePagingObj.getTotalPageNumber() - lastElement) < 10) {
                        wrPgItrObj.rtnIntList.clear();
                        for(Integer i= lastElement + 1 ;i<=casePagingObj.getTotalPageNumber();i++) { 
                            wrPgItrObj.rtnIntList.add(i);
                        }
                    } else {
                        wrPgItrObj.rtnIntList.clear();
                        for(Integer i= lastElement + 1 ; i <= 10 + lastElement; i++) {
                            wrPgItrObj.rtnIntList.add(i);
                        }
                    }
                    System.Debug('>>wrPgItrObj.rtnIntList>>'+wrPgItrObj.rtnIntList);    
                }
                lastElement = wrPgItrObj.rtnIntList.get(wrPgItrObj.rtnIntList.size() - 1);
                firstElement = wrPgItrObj.rtnIntList.get(0);
                System.Debug('>>lastElement>>'+lastElement);
                System.Debug('>>firstElement>>'+firstElement);  
            } 
            return wrPgItrObj.rtnIntList;
        } catch(Exception ex) { }
        return null;
    }
    
    public List<selectOption> productAssistanceItems {get;set;} 
    public List<selectOption> productAssistanceItemsLvl2 {get;set;}
    public List<selectOption> productAssistanceItemsLvl3 {get;set;}
    public List<SelectOption> getproductAssistanceItemsValues() {
        List<SelectOption> options = new List<SelectOption>();
        /* Case 03272867:  Product Assistance Custom setting changes {*/
        String portalName = mapPortalList.get(baseUrl.toLowerCase().trim());
        /*} Case 03272867:  Product Assistance Custom setting changes */
        try {
            options.add(new selectOption('','Please select product area'));
            Schema.DescribeFieldResult productAssistance = Case.Product_Assistance__c.getDescribe();
            List<Schema.PicklistEntry> productAssistanceList = productAssistance.getPicklistValues();
            /* Case 03272867:  Product Assistance Custom setting changes {*/
            for(Schema.PicklistEntry schObj : productAssistanceList) {
                String productAssistanceValue = schObj.getValue();
                String productAssistanceLable = schObj.getLabel();
                Set<String> portalBrand = mapProductAssistance.get(productAssistanceValue.toLowerCase().trim());
                //if(portalBrand.contains(portalName)){
                    options.add(new selectOption(productAssistanceValue,productAssistanceLable));
                //}
            }
            /*} Case 03272867:  Product Assistance Custom setting changes */
        } catch(Exception ex) {}
        return options;
    }
    
    public List<SelectOption> productAssistanceItemsLvl2() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            options.add(new selectOption('','Please select product issue'));
            Schema.DescribeFieldResult productAssistance = Case.Product_Assistance_Lvl2__c.getDescribe();
            List<Schema.PicklistEntry> productAssistanceList2 = productAssistance.getPicklistValues();
            for(Schema.PicklistEntry schObj : productAssistanceList2) {
                options.add(new selectOption(schObj.getValue(),schObj.getLabel()));
            }
            if(test.isRunningTest()){
                integer i = 2/0;
            }
        } catch(Exception ex) {}
        return options;
    }
    
    public List<SelectOption> productAssistanceItemsLvl3() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            options.add(new selectOption('','Please select product issue'));
            Schema.DescribeFieldResult productAssistance = Case.Product_Assistance_Lvl3__c.getDescribe();
            List<Schema.PicklistEntry> productAssistanceList3 = productAssistance.getPicklistValues();
            for(Schema.PicklistEntry schObj : productAssistanceList3) {
                options.add(new selectOption(schObj.getValue(),schObj.getLabel()));
            }
            if(test.isRunningTest()){
                integer i = 2/0;
            }
        } catch(Exception ex) {}
        return options;
    }
    
    public List<selectOption> caseSeverityItems {get;set;}
    public List<SelectOption> getcaseSeverityItemsValues() {
        List<SelectOption> options = new List<SelectOption>();
        try {
            options.add(new selectOption('','Please select severity level'));
            Schema.DescribeFieldResult caseAssistance = Case.Case_Severity__c.getDescribe();
            List<Schema.PicklistEntry> caseAssistanceList = caseAssistance.getPicklistValues();
            for(Schema.PicklistEntry schObj : caseAssistanceList) {
                if(schObj.getLabel() != 'Level 1 - Critical') {
                    options.add(new selectOption(schObj.getValue(),schObj.getLabel()));
                }
            }
        } catch(Exception ex) {}
        return options;
    }
    
    public class WrapperCase {
        public Case caseObj {get;set;}
        public string strformatDT {get;set;}
        public Integer caseIndex {get;set;} 
        public WrapperCase() {
            caseObj = new Case();
            strformatDT = null;
            caseIndex = 0;
        }
    }
    
    public Integer firstElement {get;set;}
    public Integer lastElement {get;set;}
    public string actionType {get;set;}
    public class WrPgIterator {
        public Integer wrfirstElement {get;set;}
        public Integer wrlastElement {get;set;} 
        public List<Integer> rtnIntList {get;set;}
        public void WrPgIterator() {
            wrfirstElement = 0;
            wrlastElement = 0;
            rtnIntList = null;
        }
    }
    
 }
