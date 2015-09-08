public  class SupportPortalControllerNew  {
//String IEE = Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=8');// For IE9 

    public  String strPostFix='';
    private static final String PAGE_PREFIX = '/apex';
    public static final String PAGE_HOME = 'SupportPortalHome'; 
    public static final String PAGE_PRODUCT = 'ATTProduct';
    public static final String PAGE_SEARCH1 = 'SupportPortalArtList?action=SearchAnswer';
    public static final String PAGE_Next = 'SupportPortalArtList';
    public static final String PAGE_SEARCH = 'SupportPortalArtList';
    public static final String PAGE_SEARCH_CUSTOM = 'SupportPortalArtListNew';
    public static final String PAGE_WHATIS_NEW = 'ATTWhatIsNew';
    public static final String PAGE_INTERNATIONALRATES = 'internationalrates';
    public static final String PAGE_CALLINGRATES = 'callingrates'; // BT Support Portal Calling Rates Page.
    public static final String PAGE_ARTICLES = 'SupportPortalArticle'; // BT Support Portal Articles Page.
    public static final String PAGE_SUPPORT_SERARCH='SupportPortalSearch';
    public static final String PAGE_CONTACT_SUPPORT='SupportPortalContact';
    public static final String PAGE_Video_Link_Page='SupportPortalVideoLink';
    public static final String PAGE_CASE_CREATE_PAGE = 'SupportPortalCaseCreate';
    public static final String URL_HOME = PAGE_PREFIX + '/' + PAGE_HOME;
    public static final String URL_PRODUCT = PAGE_PREFIX + '/' + PAGE_PRODUCT;
    public static final String URL_SEARCH = PAGE_PREFIX + '/' + PAGE_SEARCH;
    public static final String URL_SEARCH1 = PAGE_SEARCH;
    //public static final String URL_PageSEARCH=PAGE_SEARCH1;
    public static final String URL_PageSEARCH=PAGE_Next;
    public static final String ARTICLE_TYPE_PARAMETER_NAME = 't';
    public static final String CATEGORY_PARAMETER_NAME = 'c';
    public static final String KEYWORD_PARAMETER_NAME = 'k';
    public static final String PAGE_NUMBER_PARAMETER_NAME = 'p';
    public static final String ARTICLE_TYPE_LABEL_PARAMETER_NAME = 'l';
    public static final String PAGE_SORT_BY='sortBy';
    public Boolean isGuestUser{get;set;}
    public User objUser{get;set;}
    public Boolean isTokenFound{get;set;}
    public String str{get;set;}
    public Boolean isOpenCase {get; set;}
    public Boolean isHideContact {get; set;}
    public Boolean isCheckCase {get; set;}
    public Boolean theCheckPanel {get; set;}
    public Set<String> DataCategory {get; set;}
    public Map<String, Boolean> dataCategoryMap {get; set;}

    public SupportPortalControllerNew(){
        system.debug('###@@@ SupportPortalControllerNew');
        isHideContact=true;
        theCheckPanel=true;
     if(UserInfo.getUserType()=='Guest'){
        isGuestUser=true;
    }else{
        isGuestUser = false;
    }
    isTokenFound=isValidTokenFound();
    system.debug('isTokenFound'+isTokenFound);
    objUser=new User();
    if(isGuestUser!=true){
      objUser=[SELECT AboutMe, IsActive, CommunityNickname, CompanyName, Country, CreatedDate, Department, 
                      Division, Email,  Name, IsPortalEnabled, LastLoginDate, UserType, Username,Profile.Name,
                      UserRole.Name,FullPhotoUrl 
               FROM User WHERE Id =: UserInfo.getUserId()];
    
    }   
    
    
    /*Calling methods to fetch Data Category related to BT.*/
    List<RCNEW_Knowledge_Article__c> knowledgeArticleList = [SELECT Id, Brand__c, BT_Data_Category__c 
                                                             FROM RCNEW_Knowledge_Article__c WHERE Brand__c =: 'BT Business'];
    DataCategory = new Set<String>(); //getParentChildCategory();
    if(knowledgeArticleList != null && knowledgeArticleList.size() > 0 && knowledgeArticleList[0].BT_Data_Category__c != null){
        DataCategory.addAll(knowledgeArticleList[0].BT_Data_Category__c.split(',',0));  
        system.debug('#### BT Cloud Phone Data Categories = '+DataCategory); 
    }
    
    /*If contact support page, set the Id for Contact.*/
    String currentPage = ApexPages.currentPage().getUrl(); 
    if(currentPage.contains('SupportPortalContact')){
        ApexPages.currentPage().getParameters().put('pageid','contact');    
    }
}
    
    /******************************************************************************
    * @Description : Calling method to fetch Valid login token.                   *
    * @Params      : void                                                         *
    * @Return      : Boolean                                                      *
    ******************************************************************************/
    public Boolean isValidTokenFound(){
        String strToken = getValidToken();
        if(strToken!=null && strToken!=''){
            return true;
        }
        return false;
    }

    /******************************************************************************
    * @Description : Contains logic for fetching the token from URL.              *
    * @Params      : void                                                         *
    * @Return      : String                                                       *
    ******************************************************************************/
    public String getValidToken(){
        try{
            String strToken = ApexPages.CurrentPage().getParameters().get('token');
            if(strToken!=null && strToken!=''){
                String tokenUrlDecoded = EncodingUtil.urlDecode(strToken, 'UTF-8');
                tokenUrlDecoded = tokenUrlDecoded.replaceAll(' ', '+');
                Blob tokenDecodedBases64 = Encodingutil.base64Decode(tokenUrlDecoded);          
                Blob cryptoKey = Blob.valueOf('v7Y2g2webAqutAcr4DEC3uTAnaspEgA8');
                Blob initVector = Blob.valueof('da4atrABufastacr'); 
                // Decrypt the data
                Blob decryptedData = Crypto.decrypt('AES256', cryptoKey, initVector, tokenDecodedBases64);
                system.debug('###@@@decryptedData '+decryptedData);
                String tokenVal = decryptedData.toString();  
                system.debug('###@@@tokenVal '+tokenVal);  
               return tokenVal;
            }
        }catch(Exception ex){system.debug('#### Exception at line = '+ex.getLineNumber()+' , message = '+ex.getMessage());}
        return null;  
    }
    
    public PageReference validateLoginDetail(){
        try{
            system.debug('###validateLoginDetail start isTokenFound '+isTokenFound);
            if(isTokenFound==true ){
                /*if(!(getURLProtocol().equalsIgnoreCase('https'))){
                    String strUrl=URL.getCurrentRequestUrl().toExternalForm();
                    strUrl=strUrl.replaceFirst('http','https');
                    strUrl=strUrl+'?'+URL.getCurrentRequestUrl().getQuery();
                    Pagereference objPage=new Pagereference(strUrl);
                    objPage.setRedirect(true);
                    return objPage;
                }*/
                String tokenVal=getValidToken();   
                System.debug('###@@@tokenVal'+tokenVal);
                if(tokenVal != null && tokenVal != ''){
                    String loginToken = tokenVal;
                    String username;
                    String password;
                    if(loginToken != null) {
                        String[] strSplitToken = loginToken.split('&');
                        username =  strSplitToken[0].split('=')[1];
                        password =  strSplitToken[1].split('=')[1];
                        str=username+password;
                    }
                    String strPage = ApexPages.CurrentPage().getParameters().get('NEXTPAGE');
                    if(strPage!=null && strPage!='' && strPage.indexOf(strPostFix)>=0){
                        strPage='/'+strPage.removeEndIgnoreCase(strPostFix);
                    }else if(ApexPages.CurrentPage().getParameters().get('ARTICLENAME')!=null && ApexPages.CurrentPage().getParameters().get('ARTICLENAME')!=''){
                        strPage='';
                        strPage='/articles/RC_Knowledge_Article/'+ApexPages.CurrentPage().getParameters().get('ARTICLENAME');
                    }
                    PageReference pageRef= Site.login(username,password, ''+strPage);
                    pageRef.setRedirect(true);
                    return pageRef;
                }
            } 
        }catch(Exception ex){system.debug('#### Exception at line = '+ex.getLineNumber()+' , message = '+ex.getMessage());}
        return null;
    }
    
    public String getNextPageName(){
        String strPage=null;
        if(ApexPages.currentPage().getParameters().get('startURL')!=null && ApexPages.currentPage().getParameters().get('startURL')!=''){
            strPage=ApexPages.currentPage().getParameters().get('startURL');
            if(strPage!=null && strPage!='' && strPage.indexOf('/')>=0){
                strPage=strPage.substringAfterLast('/');
                 system.debug('###getNextPageName if strPage+strPostFix'+strPage+strPostFix);
                return strPage+strPostFix;
            }
        }
        return 'SupportPortalHome'+strPostFix;
    }
    
    public Pagereference login(){
        system.debug('###@@@login done '+isTokenFound);
        if(isTokenFound==true){
            system.debug('###@@@login done1 '+isTokenFound);
            return validateLoginDetail();
        }else{
            PageReference objPage=new PageReference('portal.btcloudphone.bt.com/login.asp');
            objPage.getParameters().put('p_next_page',getNextPageName());
            objPage.setRedirect(true);
            return objPage;
        }
        return null;
    }
     
    public String strUserType{get;set;}

    public Pagereference PageAuthorization(){
        if(UserInfo.getUserType()=='Guest'){
            isGuestUser=true;
        }else{
            isGuestUser=false;
            return null;
        }
        return login();
    } 
    
    public Pagereference getPageAuthorization(){
        if(UserInfo.getUserType()=='Guest'){
            isGuestUser=true;
        }else{
            isGuestUser=false;
        return null;
        }
        return login();
    } 

    
    public pagereference redirectToDetailPage(){
        system.debug('redirectToDetailPage start');
        try{
            if(ApexPages.CurrentPage().getParameters().get('ARTICLEID')!=null && ApexPages.CurrentPage().getParameters().get('ARTICLEID')!=''){
                String strParam=ApexPages.CurrentPage().getParameters().get('ARTICLEID');
                String strArticleNumber='%'+strParam+'';
                if(strParam.length()<4){
                    strArticleNumber='%0'+strParam+'';
                }
                String strURLName='Not Found';
                // List<RC_Knowledge_Article__DataCategorySelection> lstDataCategory=new List<RC_Knowledge_Article__DataCategorySelection>();
                for(RC_Knowledge_Article__DataCategorySelection objData:[SELECT r.Parent.UrlName,r.DataCategoryName, r.DataCategoryGroupName,r.Parent.ArticleNumber,
                                                                                r.Parent.KnowledgeArticleId, r.ParentId 
                                                                         FROM RC_Knowledge_Article__DataCategorySelection r 
                                                                         WHERE r.Parent.PublishStatus = 'Online' AND ((r.Parent.ArticleNumber like: strArticleNumber) OR 
                                                                              (r.Parent.UrlName =: strParam) OR (r.Parent.KnowledgeArticleId=:strParam) OR (r.Parent.Id =: strParam)) 
                                                                         order by r.Parent.UrlName limit 20]){
                   if(objdata.DataCategoryGroupName=='Brand' && (objdata.DataCategoryName=='ALL' || objdata.DataCategoryName=='BT')){
                        strURLName=objdata.Parent.UrlName;
                   }                                                                
                }
                if(strURLName!='Not Found'){
                    String strPage='/articles/RC_Knowledge_Article/'+strURLName+'?retUrl=';
                    Pagereference pageRef= new Pagereference(strPage);
                    pageRef.setRedirect(true);
                    system.debug('redirectToDetailPage start pageRef'+ pageRef);
                    return pageRef;
              
                }
            }
        }catch(Exception ex){}
        return null;
    }

    public String categoryParameterName {
        get { return CATEGORY_PARAMETER_NAME; }
    }

    public String keywordParameterName {
        get { return KEYWORD_PARAMETER_NAME; }
    }

    public String articleTypeParameterName {
        get { return ARTICLE_TYPE_PARAMETER_NAME; }
    }

    public String articleTypeLabelParameterName {
        get { return ARTICLE_TYPE_LABEL_PARAMETER_NAME; }
    }

    public String pageNumberParameterName {
        get { return PAGE_NUMBER_PARAMETER_NAME; }
    }

    public String paramByParamId(String paramId, String defaultValue) {
        if (ApexPages.currentPage().getParameters() == null) {
            return defaultValue;
        } else {
            String value = ApexPages.currentPage().getParameters().get(paramId);
            return (value == null) ? defaultValue : value;
        }
    }

    public Integer paramByParamId(String paramId, Integer defaultValue) {
        if (ApexPages.currentPage().getParameters() == null) {
            return defaultValue;
        } else {
            String value = ApexPages.currentPage().getParameters().get(paramId);
            return (value == null) ? defaultValue : Integer.valueOf(value);
        }
    } 

    public Integer currentPageNumber {
        get {
            if (currentPageNumber == null) {
                currentPageNumber = paramByParamId(PAGE_NUMBER_PARAMETER_NAME, 1);
            }
            return currentPageNumber;
        }
        set;
    }

    public String currentCategory {
        get {
            if (currentCategory == null) {
                currentCategory = paramByParamId(CATEGORY_PARAMETER_NAME, getRootCategoryName());
            }
            return currentCategory;
        }
        set;
    }
    public String currentCategoryName {
               get {
            if (currentCategory!= null) {
                currentCategoryName = currentCategory.replace('_',' ');
            }
            return currentCategoryName; 
        }
        set;
    }
    public String currentArticleType {
        get {
            if (currentArticleType == null) {
                currentArticleType = paramByParamId(ARTICLE_TYPE_PARAMETER_NAME, '');
            }
            return currentArticleType;
        }
        set;
    }

    public String currentArticleTypeLabel {
        get {
            if (currentArticleTypeLabel == null) {
                currentArticleTypeLabel = paramByParamId(ARTICLE_TYPE_LABEL_PARAMETER_NAME, '');
            }
            return currentArticleTypeLabel;
        }
        set;
    }

    public String currentKeyword {
        get {
            if (currentKeyword == null) {
                currentKeyword = paramByParamId(KEYWORD_PARAMETER_NAME, '');
            }
            return currentKeyword;
        }
        set;
    }
    public String currentKeywordSerach {
        get {
            if (currentKeyword == null || currentKeyword =='') {
                currentKeyword = paramByParamId(KEYWORD_PARAMETER_NAME, '');
                return currentKeyword ;
            }
            return '\"'+currentKeyword+'\"';
           }
        set;
    }

    public static RCSiteSetup__c siteSetup {
        get {
            if (siteSetup == null) {
                try {
                    String siteName = Site.getName();
                        if (siteName == null || siteName.length()==0) {
                        siteName = 'TestPKBSiteSetup';
                    }
                    if(Test.isRunningTest()){
                       //  siteName = 'ATT';
                        siteName = 'btcloudphone';
                   }
                    siteSetup = [
                       SELECT RCSiteName__c, RootCategoryName__c, CategoryGroupName__c, CacheMaxAge__c,
                       Category1Description__c, Category2Description__c, Category3Description__c,
                       Category4Description__c, Category5Description__c, Category6Description__c,
                       HomeAdText__c, HomeAdTitle__c, Brand_Filter__c
                       FROM RCSiteSetup__c
                       WHERE RCSiteName__c = :siteName ];
                       //WHERE RCSiteName__c = :'rcsupport'];
                 } catch (QueryException  e) {
                    // can't throw an exception here in order to prevent tests from failing before creating an PKB Site Setup
                    siteSetup = new RCSiteSetup__c();
                }
            }
            return siteSetup;
        }
        set;
    }

    public RCSiteSetup__c getSiteSetup() {
        return siteSetup;
    }


    private String[] categoryDescriptions;

    public String[] getCategoryDescriptions() {
        if (categoryDescriptions == null) {
            categoryDescriptions = new String[]{};
            categoryDescriptions.add(siteSetup.category1Description__c == null ? '' : siteSetup.category1Description__c);
            categoryDescriptions.add(siteSetup.category2Description__c == null ? '' : siteSetup.category2Description__c);
            categoryDescriptions.add(siteSetup.category3Description__c == null ? '' : siteSetup.category3Description__c);
            categoryDescriptions.add(siteSetup.category4Description__c == null ? '' : siteSetup.category4Description__c);
            categoryDescriptions.add(siteSetup.category5Description__c == null ? '' : siteSetup.category5Description__c);
            categoryDescriptions.add(siteSetup.category6Description__c == null ? '' : siteSetup.category6Description__c);
        }
        return categoryDescriptions;
    }

    public String getHomeAdTitle() {
        return siteSetup.HomeAdTitle__c == null ? '' : siteSetup.HomeAdTitle__c;
    }

    public String getHomeAdText() {
        return siteSetup.HomeAdText__c == null ? '' : siteSetup.HomeAdText__c;
    }

    public String getRootCategoryName() {
        return siteSetup.RootCategoryName__c == null ? '' : siteSetup.RootCategoryName__c;
    }

    public String getCategoryGroupName() {
        return siteSetup.CategoryGroupName__c == null ? '' : siteSetup.CategoryGroupName__c;
    }
    
    public String getBrandFilter() {
        return siteSetup.Brand_Filter__c == null ? '' : siteSetup.Brand_Filter__c;
    }
     public String getServiceFilter() {
        String strServiceFilter=ApexPages.CurrentPage().getParameters().get('serviceFilter');
       if(strServiceFilter==null){
          // return siteSetup.Brand_Filter__c == null ? '' : siteSetup.Brand_Filter__c;
          //return siteSetup.Brand_Filter__c == null ? '' : 'ALL';
          strServiceFilter = '';
       }else{
           strServiceFilter = 'Service:'+strServiceFilter;       
       }
       return strServiceFilter;
    }
    
     public String getServiceFilterURL() {
        String strServiceFilter=ApexPages.CurrentPage().getParameters().get('serviceFilter');
       if(strServiceFilter==null){
          // return siteSetup.Brand_Filter__c == null ? '' : siteSetup.Brand_Filter__c;
          //return siteSetup.Brand_Filter__c == null ? '' : 'ALL';
          strServiceFilter = '';
       }else{
           strServiceFilter = strServiceFilter;       
       }
       return strServiceFilter;
    }
    
    
    public String getURLCategory() {
        return ApexPages.CurrentPage().getParameters().get('c');
    }
    
    public String getFramedParam() {
        return ApexPages.CurrentPage().getParameters().get('framed');
    }

    
    public String getAuthToken()
    {
       /* String strToken = ApexPages.CurrentPage().getParameters().get('token');
        if(strToken == null || strToken.Trim() == '') {
            strToken = '';
            String retUrl = ApexPages.CurrentPage().getParameters().get('retURL');
            if(retURL != null) {
                retUrl = Encodingutil.urlDecode(retUrl, 'UTF-8');
                List<String> params = retUrl.split('&');
                for(String param : params) {
                    if(param.startsWith('token')){
                        strToken = param;
                        break;
                    }
                } 
            }           
         } else {         
            strToken = 'token='+ strToken;
         } */     
        return '';
    } 
    public String getPageId() {
        String strgetpageid = '';
        Boolean isHomePage=false;
        strgetpageid = ApexPages.CurrentPage().getParameters().get('pageid');
        String pagename = ApexPages.currentPage().getUrl();
        if(pagename == '/apex/SupportPortalHome'){
            strgetpageid = 'home';
            isHomePage=true;
        } 
         if(isHomePage==false && (strgetpageid==null || strgetpageid=='')  ){
            if(ApexPages.CurrentPage().getParameters().get('token')!=null){
              strgetpageid = 'home';
            }else{
               strgetpageid='knowledge';
               }
          }   
        
        
        return strgetpageid;
    }
    public Long getCacheMaxAge() {
        return siteSetup.CacheMaxAge__c == null ? 0 : Math.roundToLong(siteSetup.CacheMaxAge__c);
    }

    public String getParentId() {
        return ApexPages.CurrentPage().getParameters().get('parentId');
    }
   
    public String getHomeUrl() {
        return URL_HOME;
    }

    public String getProductUrl() {
        return URL_PRODUCT;
    }

    public String getSearchUrl() {
        return URL_SEARCH;
    }
    public String getSearchPageUrl() {
        return URL_PageSEARCH;
    }
    public String getSupportSearchPageUrl() {
        return PAGE_SUPPORT_SERARCH;
    }
      public String getSearchUrl1() {
        return URL_SEARCH1;
    }
    
    public String getHomePage() {
        return PAGE_HOME;
    }

    public String getProductPage() {
        return PAGE_PRODUCT;
    }

    public String getSearchPage() {
        return PAGE_SEARCH;
    }

    public String getPage(String url) {
        if (url.contains('?')) {
            Integer i = url.indexOf('?');
            url = url.substring(0, i);
        }
        while (url.endsWith('/')) {
            url = url.substring(0, url.length()-1);
        }
        if (url.contains('/')) {
            Integer i = url.lastIndexOf('/');
            url = url.substring(i+1);
        }
        return url;
    }


    public PageReference currentPageReference {
        get {
            if (currentPageReference == null) {
                currentPageReference = ApexPages.currentPage();
            }
            return currentPageReference;
        }
        set;
    }

    public String currentPage {
        get {
                if (currentPage == null) {
                    currentPage = getPage(currentPageReference.getUrl());
                }
                return currentPage;
            }
            set;
    }

    public Boolean isPage(String pageName) {
        return currentPage.toLowerCase() == (pageName.toLowerCase());
    }

    public Boolean getIsHomePage() {
        return isPage(PAGE_HOME);
    }
    public Boolean getCaseCreatePage() {
        return isPage(PAGE_CASE_CREATE_PAGE);
    }
    
    public Boolean getIsContactSupportPage() {
        return isPage(PAGE_CONTACT_SUPPORT);
    }
    public Boolean getIsProductPage() {
        return isPage(PAGE_PRODUCT);
    }

    public Boolean getIsSearchPage() {
        return isPage(PAGE_SEARCH);
    }
    public Boolean getIsCustomArticleListPage(){
        return isPage(PAGE_SEARCH_CUSTOM);
    }
     public Boolean getIsVideoLinkPage(){
        return isPage(PAGE_Video_Link_Page);
    }
    
    public Boolean getWhatIsNewPage() {
        return isPage(PAGE_WHATIS_NEW);
    }
     public Boolean getWhatIsNewPageNew() {
        return isPage('WhatIsNew');
    }
    public Boolean getINTERNATIONALPage() {
        return isPage(PAGE_INTERNATIONALRATES);
    }
    public Boolean getCallingRatesPage() {
        return isPage(PAGE_CALLINGRATES);
    }
    public Boolean getArticlePage(){
        return isPage(PAGE_ARTICLES);
    }
    
    public Boolean getIsExternalPage() {
        return !(getIsHomePage() || getIsProductPage() || getIsSearchPage() || getIsCustomArticleListPage() || getIsContactSupportPage()
            || getWhatIsNewPage() || getWhatIsNewPageNew() || getCallingRatesPage() || getArticlePage() || getCaseCreatePage());
        //  return !(getIsHomePage() );
    }



   public PageReference doSearch() {
       /* if (currentKeyword.length()<2) {
            return cleanKeyword();
        }*/
        PageReference pg = new PageReference(getSearchUrl());
        pg.getParameters().put(KEYWORD_PARAMETER_NAME, currentKeyword);
        pg.getParameters().put(CATEGORY_PARAMETER_NAME, currentCategory);
        pg.getParameters().put('action', 'SearchAnswer');
        pg.getParameters().put(PAGE_SORT_BY, strSortOrderDirection);
        if (getIsExternalPage()) {
            pg.setRedirect(true);
        }
           pg.setRedirect(true);
        return pg;
   }


   public PageReference cleanKeyword() {
        PageReference pg = new PageReference(getProductUrl());
        pg.getParameters().put(CATEGORY_PARAMETER_NAME, currentCategory);
        pg.getParameters().put(KEYWORD_PARAMETER_NAME, '');
        currentKeyword = '';
        if (getIsExternalPage()) {
            pg.setRedirect(true);
        }
     
        return pg;
   }

    public Boolean getCanUserSeeKnowledge() {
        //return [select permissionsviewknowledge from profile where id = :UserInfo.getProfileId()].permissionsviewknowledge;
        return true;
    }

 public Boolean getIsContact(){
    String strParam=ApexPages.currentPage().getParameters().get('attContactUs');
     if(strParam == 'contact'){
   return true;
   }
   return false;
 }
   public Boolean getIsAnswerSearch(){ 
   String strParam=ApexPages.currentPage().getParameters().get('action');
     if(strParam !=null && strParam!='' && strParam.contains('?')){
       return true;
     }
     if(strParam == 'SearchAnswer'){
   return true;
   }
   if(ApexPages.currentPage().getParameters().get('retURL')!=null){
     return true;
   }
   return false;
   
   }
   
    public Boolean getIsArticleDetailsPage(){ 
     if(ApexPages.currentPage().getParameters().get('retURL')!=null){
     return true;
   }
   return false;
    }
   
  public String strSearchCategory{get;set;}
 // public String strSortOrderDirection{get;set;}
  public String strSortOrderAscORDec{get;set;}
  
   public String strSortOrderDirection{
      get{
      if(ApexPages.currentPage().getParameters().get('sortBy')==null){
        //return 'mostViewed';
        return 'title';
      }
      return ApexPages.currentPage().getParameters().get('sortBy');
      }
       set;
     }
  
   public PageReference doAdvanceSearch() {
       /* if (currentKeyword.length()<2) {
            return cleanKeyword();
        }*/
        PageReference pg = new PageReference(getSearchUrl());
        pg.getParameters().put(KEYWORD_PARAMETER_NAME, currentKeyword);
        pg.getParameters().put(CATEGORY_PARAMETER_NAME, strSearchCategory);
        pg.getParameters().put('action', 'SearchAnswer');
        if (getIsExternalPage()) {
            pg.setRedirect(true);
        }
         //pg.getParameters().put('test1', strSortOrderDirection);
         //pg.getParameters().put('test2', strSortOrderAscORDec);
           pg.setRedirect(true);
        return pg;
   }
   
  public PageReference emailSend(){
   String page=ApexPages.currentPage().getParameters().get('emailPage');
   String recMail=ApexPages.currentPage().getParameters().get('recMail');
   String senderMail=ApexPages.currentPage().getParameters().get('senderMail');
   String senderName=ApexPages.currentPage().getParameters().get('sendername');
   String strTitle='';
   
  if(page!=null && page!=''){
     page=page.replace('\'','');
  }
  
  if(page!=null){
    strTitle=ApexPages.currentPage().getParameters().get('title');
    if(strTitle!=null){
    strTitle=strTitle.replace('\'','');
    }
   }
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
   //String strTo='kanishk.singh@simplion.com';
    String strTo=recMail;
    String strMessageBody= '<div>The following answer has been forwarded to you by '+senderName+
                            ' - <a href=#>'+senderMail+'.</a><br/>'+
                           ' (The sender email address has not been verified.)</div><br/><br/> '+
                           ' <div style=background-color:#e0e0e0;width:100%><B>Summary</B></div><div>'+
                           //' Supported File Attachments for Faxes<br/> '+
                           strTitle+
                           '<br/> <a href='+page+'>You can view this answer here.</a> '+
                           ' </div>';
    
            String[] toAddresses = new String[] {strTo}; 
            mail.setToAddresses(toAddresses);
            //mail.setSenderDisplayName(senderName);
             mail.setSenderDisplayName('');
            mail.setSubject('FWD Answer: '+strTitle);
          //mail.setPlainTextBody('Test mail\n\n'+page+'\n\n'+recMail+'\n'+senderMail+'\n'+senderName);  
            mail.setHtmlBody(strMessageBody); 
            try{            
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }catch(Exception e){}
          return null;
   } 
     
  
    public Pagereference openCreateCase(){
        return new Pagereference('/SupportPortalCaseCreate?pageid=contact');
    }
    
    public Pagereference openCase(){
        return new Pagereference('https://portal.btcloudphone.bt.com/login.asp?p_next_page=RCSupportPortalCreateNewCase');
    }


    public Pagereference openMyCase(){
        system.debug('$$$isCheckCase'+isCheckCase);
        theCheckPanel = true;
        return new Pagereference('https://portal.btcloudphone.bt.com/login.asp?p_next_page=RCContactSupp'); 
    } 

public Boolean getUKPortal(){
        if(Site.getName()!=null && Site.getName()!='' && (Site.getName()).lastIndexOfIgnoreCase('RCSupportPortalUK')>-1){
        return true;
        }
        return false;
    }
    
    /*********************************************************************************************
    * @Description : Method to fetch the RC Knowledge Article Version Details.                   *
    * @Params      : void                                                                        * 
    * @Return      : List<Id>                                                                    * 
    *********************************************************************************************/
    public List<Id> getKnowledgeArticleVersionDetails(){
        List<Id> knowledgeArticlekvaList = new List<Id>();
    
        for(RC_Knowledge_Article__kav thisRecord : [SELECT  ArticleNumber,ArticleType,Details__c,Id,Key_Words__c,KnowledgeArticleId,
                                                            Language,PublishStatus,Ranking__c,SourceId,Summary,Title,UrlName,VersionNumber 
                                                    FROM RC_Knowledge_Article__kav 
                                                    WHERE PublishStatus='online' AND language ='en_US' LIMIT 50000]){
            knowledgeArticlekvaList.add(thisRecord.Id);    
        }   
        return knowledgeArticlekvaList;
    }

    /*********************************************************************************************
    * @Description : Method to fetch the RC Knowledge Article Data Category.                     *
    * @Params      : List<Id>                                                                    * 
    * @Return      : Set<Id>                                                                     * 
    *********************************************************************************************/
    public Set<String> getKnowledgeArticleDataCategory(List<Id> knowledgeArticlekvaList, String brand){
        
        Set<String> DataCategory = new Set<String>();
        Set<Id> knowledgeArticleParentId = new Set<Id>();
        List<RC_Knowledge_Article__DataCategorySelection> knowledgeArticleDataCategory = [SELECT Id,DataCategoryName, ParentId 
                                                                                          FROM RC_Knowledge_Article__DataCategorySelection 
                                                                                          WHERE ParentId IN: knowledgeArticlekvaList LIMIT 50000];
        
        for(RC_Knowledge_Article__DataCategorySelection thisRecord : knowledgeArticleDataCategory){
            if(thisRecord.DataCategoryName.equalsIgnoreCase(brand)){
                knowledgeArticleParentId.add(thisRecord.ParentId);  
            }
        }
    
        for(RC_Knowledge_Article__DataCategorySelection thisRecord : knowledgeArticleDataCategory){
            if(knowledgeArticleParentId.contains(thisRecord.ParentId)){
                DataCategory.add(thisRecord.DataCategoryName);  
            }
        }
        return DataCategory;
    }
    
    /*********************************************************************************************
    * @Description : Method to create Data Category Map.                                         *
    * @Params      : Set<String>                                                                 * 
    * @Return      : Map<String, Boolean>                                                        * 
    *********************************************************************************************/
    public Map<String, Boolean> createDataCategoryMap(Set<String> dataCategorySet){
        Map<String, Boolean> dataCategoryMap = new Map<String, Boolean>();
        for(String thisRecord : dataCategorySet){
            dataCategoryMap.put(thisRecord.replace('_',' '), true); 
        }   
        return dataCategoryMap;
    }
    
    /*********************************************************************************************
    * @Description : Method to fetch the Data Category Structure.                                *
    * @Params      :                                                                             * 
    * @Return      : Map<String, Set<String>>                                                    * 
    *********************************************************************************************/
    public Map<String, Set<String>> createDataCategoryStructure(){
        
        List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
        Map<String, Set<String>> dataCategoryParentChildMap = new Map<String, Set<String>>();
        
        //Creating a list of pair objects to use as a parameter for the describe call
        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();         
        DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
        p.setSobject('KnowledgeArticleVersion');
        p.setDataCategoryGroupName('Topic');
        pairs.add(p);
         
        describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
        if(describeCategoryStructureResult != null && describeCategoryStructureResult.size() > 0){
            
            DescribeDataCategoryGroupStructureResult singleResult = describeCategoryStructureResult[0];
            //Get the top level categories
            DataCategory [] toplevelCategories = singleResult.getTopCategories();
            //Recursively get all the categories
            List<DataCategory> allCategories = getAllCategories(toplevelCategories);
                

            for(DataCategory category : allCategories) {
               //Get the name of the category
               category.getName();
               system.debug('#### category.getName() - '+category.getName());
               //Get the label of the category
               category.getLabel();
               system.debug('#### category.getLabel() - '+category.getLabel());
               //Get the list of sub categories in the category
               DataCategory [] childCategories = category.getChildCategories();
               if(category.getChildCategories() != null && category.getChildCategories().size() > 0){
                    for(DataCategory childCategory : category.getChildCategories()) {
                        if(dataCategoryParentChildMap.get(category.getName()) != null){
                            dataCategoryParentChildMap.get(category.getName()).add(childCategory.getName());
                        }else{
                            dataCategoryParentChildMap.put(category.getName(),new Set<String>{childCategory.getName()});
                        }
                    }
                }
               system.debug('#### dataCategoryParentChildMap - '+dataCategoryParentChildMap);
            }
         }  
        return dataCategoryParentChildMap;      
    }
    
    /*********************************************************************************************
    * @Description : Method to fetch the Data Category Structure.                                *
    * @Params      :                                                                             * 
    * @Return      : Map<String, Set<String>>                                                    * 
    *********************************************************************************************/
    public Set<String> getParentChildCategory(){
        
        Set<String> DataCategory = new Set<String>();
        Map<String, Boolean> dataCategoryMap = new Map<String, Boolean>();
        
        try{
            DataCategory = getKnowledgeArticleDataCategory(getKnowledgeArticleVersionDetails(), 'BT');
            system.debug('#### Data Category Set = '+DataCategory);
            dataCategoryMap = createDataCategoryMap(DataCategory);
            system.debug('#### Data Category Map = '+dataCategoryMap);
            Map<String, Set<String>> dataCategoryParentChildMap = createDataCategoryStructure();    
            for(String parentCategory : dataCategoryParentChildMap.keySet()){
                if(dataCategoryParentChildMap != null && DataCategory != null && !DataCategory.isEmpty() && 
                  !dataCategoryParentChildMap.get(parentCategory).isEmpty()){
                    for(String thisCategory : DataCategory){
                        if(dataCategoryParentChildMap.get(parentCategory).contains(thisCategory)){
                            DataCategory.add(parentCategory);
                        }
                    }   
                }   
            }
        }catch(Exception ex){
            system.debug('#### Exception at Line = '+ex.getLineNumber()+' ,Message = '+ex.getMessage());    
        }
        return DataCategory;
    }
    
    /*********************************************************************************************
    * @Description : Method to fetch the Data Category Structure.                                *
    * @Params      : DataCategory []                                                             * 
    * @Return      : DataCategory []                                                             * 
    *********************************************************************************************/
    private static DataCategory[] getAllCategories(DataCategory [] categories){
        if(categories.isEmpty()){
            return new DataCategory[]{};
        } else {
            DataCategory [] categoriesClone = categories.clone();
            DataCategory category = categoriesClone[0];
            DataCategory[] allCategories = new DataCategory[]{category};
            categoriesClone.remove(0);
            categoriesClone.addAll(category.getChildCategories());
            allCategories.addAll(getAllCategories(categoriesClone));
            return allCategories;
        }
    }
    
    public Boolean getIsKnowledgePage(){
        String pageURL=ApexPages.currentPage().getUrl();
        if(pageURL!=null && pageURL.contains('knowledge/TOCArticleRendererPkb.apexp')){
            return true;
        }
        return false;
    }
    
    
}// End of Class.
