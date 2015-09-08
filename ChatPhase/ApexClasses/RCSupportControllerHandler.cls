public class RCSupportControllerHandler{
public String str{get;set;}
public Boolean isGuestUser{get;set;}
public String strSeesionId{get;set;}
public Boolean isTokenFound{get;set;}
public String strPageUrl{get;set;}
//public  String strPostFix='_rccustomer';
public  String strPostFix='';
public User objUser{get;set;}
public String strLCClassName{get;set;}
public map<String,String> mapArticleUrl{get;set;}
public map<String,String> mapArticleSummary{get;set;}
public String siteArticle {get;set;}
public List<String> articleOrderedList {get;set;}
public String CurrentURl{get;set;}
public String defaultName{get;set;}
public String labelName{get;set;}
public String currentSiteURL {get;set;}
public String currentPageName{get;set;}
public String source{get;set;}
public String test{get;set;}


public RCSupportControllerHandler(){
	test = Site.getName();
	if (apexpages.currentPage().getParameters().get('labelName')!=null && apexpages.currentPage().getParameters().get('labelName')!= '')
		labelName = apexpages.currentPage().getParameters().get('labelName');
	else
		labelName = '';
	System.debug('labelname is ~~~~~~~~~~~~~~~~~~~'+labelName);	
	if(UserInfo.getUserType()=='Guest'){
		isGuestUser=true;
	}else{
		isGuestUser=false;
	}
	// CHANGES STARTS FOR CSV BASED ARTICLE LISTING
    	mapArticleUrl = new Map<String,String>();
    	mapArticleSummary = new Map<String,String>();
   		articleOrderedList = new List<String>();
    // CHANGES ENDS FOR CSV BASED ARTICLE LISTING
	isTokenFound=isValidTokenFound();
	objUser=new User();
	if(isGuestUser!=true){
	  objUser=[SELECT AboutMe, IsActive, CommunityNickname, CompanyName, Country, CreatedDate, Department, Division, Email,  Name, IsPortalEnabled, LastLoginDate,
                UserType, Username,Profile.Name,UserRole.Name,FullPhotoUrl FROM User where id=:UserInfo.getUserId()];
	}   
	CurrentURl = Site.getBaseUrl();
        system.debug('======================='+CurrentURl);
    if(CurrentURl.contains('rcsupportCA2012')||CurrentURl.contains('success.ringcentral.ca')){
    	defaultName ='Canada';
    }else {
    	defaultName ='United States';
	}
	if(String.isNotBlank(ApexPages.CurrentPage().getParameters().get('LCtabId'))){
		strLCClassName=ApexPages.CurrentPage().getParameters().get('LCtabId');
	}else{
	 strLCClassName='getting_0';
	}
	 mapArticleUrl = knowledgeArticleMap('ArticleNaviagationListForUSCAandUK', (getUKPortal() ? 'UK' :'US/CA'));
}


/************************ GET DOCUMENT FOR ARTICLE LISTING **********************************/

public PageReference setPageParameter(){
	PageReference pageRef;
	String labelName = apexpages.currentPage().getParameters().get('labelName');
	System.debug('labelName>>>>>>>>>>>>>>>>>>>>>>>>>>>'+ apexpages.currentPage().getParameters().get('labelName')+'===='+ labelName);
	System.debug('URL is >>>>>>>>>'+currentSiteURL);
	if(source.equalsIgnoreCase('learningCenterPage'))
		 pageRef = new PageReference(currentSiteURL+'RCSupportPortalLearningCenter?LCtabId=settings_21&labelName=learning_center');
	else if(source.equalsIgnoreCase('knowledge_base')) 
		 pageRef = new PageReference(currentSiteURL+'RCSupportPortalLearningCenter?LCtabId=number_0&labelName=knowledge_base');		 
	else if(source.equalsIgnoreCase('numberTransferPage')) 
		 pageRef = new PageReference(currentSiteURL+'RCSupportPortalLearningCenter?LCtabId=number_0&labelName=learning_center');
	
	return pageRef;
}

  public static List<Document> getMyDocument(String docName){
        return [SELECT body, Name, bodyLength, ContentType, Url FROM Document WHERE Name = :docName];
    }
/*********************************************************/  
 public Map<String,String> knowledgeArticleMap(String docName, String brandName){
        String[] fileLines = new String[]{};
        
        List<Document> lstDoc = getMyDocument(docName);
        if(lstDoc != null && lstDoc.size() != 0 && lstDoc[0].body != null) {
            try {
                String csvFile= lstDoc[0].body.toString();
                fileLines = csvFile.split('#EOL#');
                Integer counter = 0;
                for(String line : fileLines){
                    if(!String.isBlank(line)&& line != '' && line != null && ++counter > 1) {
                        String[] inputvalues = line.split(',\\*-\\*,');
                        if(inputvalues != null && (inputvalues.size() == 3 || inputvalues.size() == 4)){
                    		if(brandName.containsIgnoreCase('UK')){
                    			if((inputvalues[0]).containsIgnoreCase('UK')){
                       				mapArticleUrl.put(inputvalues[1].replaceAll('"','').trim(),inputvalues[2].trim());
                       				articleOrderedList.add(inputvalues[1].replaceAll('"','').trim());
                    			}
                    		} else if(brandName.containsIgnoreCase('US')){
                    			if((inputvalues[0]).containsIgnoreCase('US/CA')){
                       				mapArticleUrl.put(inputvalues[1].replaceAll('"','').trim(),inputvalues[2].trim());
                       				if(inputvalues.size() == 4) {
                       					mapArticleSummary.put(inputvalues[1].replaceAll('"','').trim(),(String.isBlank(inputvalues[3]) ? '' : inputvalues[3].trim())); 
                   					} 
                       				articleOrderedList.add(inputvalues[1].replaceAll('"','').trim());
                    			}
                    		}
                        }
                    }
                }
            } catch(exception ex){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage());
                system.debug(ex.getMessage());
            }
        } else {
        	mapArticleUrl.put('No articles configured.','No articles configured.');
        	mapArticleSummary.put('No articles configured.', '');
        	articleOrderedList.add('No articles configured.');
        }
        return  mapArticleUrl;
    }
 public PageReference showTabsDetail(){
 	PageReference objPage=new PageReference('/RCSupportPortalLearningCenter');
 	objPage.getParameters().put('LCtabId',strLCClassName);
 	return objPage;
 } 
  public PageReference updateUserProfile() {
         try{
            update objUser;
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Profile Successfully updated');
            ApexPages.addMessage(msg);
        }catch(Exception e ){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,
            e.getMessage());
            ApexPages.addMessage(msg);
        }
     return null;
  }
public Boolean isValidTokenFound(){
	 String strToken =getValidToken();
	 if(strToken!=null && strToken!=''){
	 	return true;
	 }
	return false;
}

	public String getURL() {
		return Site.getName();
	}
	
	public Boolean getUKPortal(){
		if(Site.getName()!=null && Site.getName()!='' && (Site.getName()).lastIndexOfIgnoreCase('RCSupportPortalUK')>-1){
		return true;
		}
		return false;
	}


public String strPageUrl2{get;set;}

public Pagereference validateLoginDetail(){
	  try{
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
          if(tokenVal!=null && tokenVal!=''){
          	String loginToken=tokenVal;
		    string username;
			string password;
			
			if(loginToken != null) {
				String[] strSplitToken = loginToken.split('&');
				username = 	strSplitToken[0].split('=')[1];
				password = 	strSplitToken[1].split('=')[1];
				str=username+password;
			}
			String strPage = ApexPages.CurrentPage().getParameters().get('NEXTPAGE');
			if(strPage!=null && strPage!='' && strPage.indexOf(strPostFix)>=0){
				strPage='/'+strPage.removeEndIgnoreCase(strPostFix);
			}else if(ApexPages.CurrentPage().getParameters().get('ARTICLENAME')!=null && ApexPages.CurrentPage().getParameters().get('ARTICLENAME')!=''){
				 strPage='';
				 strPage='/articles/RC_Knowledge_Article/'+ApexPages.CurrentPage().getParameters().get('ARTICLENAME');
			}
			//Pagereference pageRef= Site.login(username,password, ''+getRetPageName());
			Pagereference pageRef= Site.login(username,password, ''+strPage);
			//Pagereference pageRef= Site.login(username,password, '/RCSupportPortalSearch');
			pageRef.setRedirect(true);
			return pageRef;
	 }
	   } 
	  //} 
	  }catch(Exception e){} 
	return null;
}

/*public String getRetPageName(){
	String strPage = ApexPages.CurrentPage().getParameters().get('NEXTPAGE');
	if(strPage!=null && strPage!=''){
		return '/'+strPage;
	}else if(ApexPages.currentPage().getParameters().get('startURL')!=null && ApexPages.currentPage().getParameters().get('startURL')!=''){
		
		strPage=ApexPages.currentPage().getParameters().get('startURL');
		return strPage;
	}
	return '/RCSupportPortalHome';
}
*/
public String getNextPageName(){
       String strPage=null;
      
       if(ApexPages.currentPage().getParameters().get('startURL')!=null && ApexPages.currentPage().getParameters().get('startURL')!=''){
		strPage=ApexPages.currentPage().getParameters().get('startURL');
		if(strPage!=null && strPage!='' && strPage.indexOf('/')>=0){
			strPage=strPage.substringAfterLast('/');
			return strPage+strPostFix;
		}
		
	}
	return 'RCSupportPortalHome'+strPostFix;
}
public String getValidToken(){
	  //try{
	  String strToken = ApexPages.CurrentPage().getParameters().get('token');
	   if(strToken!=null && strToken!=''){
	 	    String tokenUrlDecoded = EncodingUtil.urlDecode(strToken, 'UTF-8');
            tokenUrlDecoded = tokenUrlDecoded.replaceAll(' ', '+');
            Blob tokenDecodedBases64 = Encodingutil.base64Decode(tokenUrlDecoded);          
            Blob cryptoKey = Blob.valueOf('v7Y2g2webAqutAcr4DEC3uTAnaspEgA8');
            Blob initVector = Blob.valueof('da4atrABufastacr');
            // Decrypt the data
            Blob decryptedData = Crypto.decrypt('AES256', cryptoKey, initVector, tokenDecodedBases64);
            String tokenVal = decryptedData.toString();    
                // it is fixed for mul
           return tokenVal;
	   }
	  //}catch(Exception e){}
	   return null;  
	
}

/*public Pagereference loginUsingToken(){
	 if(isTokenFound==true){
		return validateLoginDetail();
	}
	return null;
}*/

public Pagereference login(){
	if(isTokenFound==true){
		return validateLoginDetail();
	}else{
			PageReference objPage=new PageReference('https://service.ringcentral.com/login.asp');
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
	}//strPageUrl=ApexPages.currentPage().getUrl();
	//return null;
	return login();
} 
public Pagereference getPageAuthorization(){
	if(UserInfo.getUserType()=='Guest'){
		isGuestUser=true;
	}else{
		isGuestUser=false;
		return null;
	}//strPageUrl=ApexPages.currentPage().getUrl();
	//return null;
	return login();
} 


public Pagereference openCase(){
	
	//return new Pagereference('/RCSupportAdvCaseCreate');
	return new Pagereference('/RCSupportPortalCreateNewCase');
	
}
public Pagereference openMyCase(){
	
	return new Pagereference('/RCSupportAdvMyCases');
	
}

 /*public String getUserDetailToken(){
  	 String strContent='';
  	 String strToken ='un=1234567kanishk.singh345.simpplion.com@rc.com&pw=rc1360308545408';
            // Use generateAesKey to generate the private key
            Blob cryptoKey1 = Blob.valueOf('v7Y2g2webAqutAcr4DEC3uTAnaspEgA8');
            Blob initVector1 = Blob.valueof('da4atrABufastacr');
            // Generate the data to be encrypted.
            Blob data = Blob.valueOf(strToken);
            // Encrypt the data and have Salesforce.com generate the initialization vector
            Blob encryptedData = Crypto.encrypt('AES256', cryptoKey1, initVector1, data);
            String strBase64Encoded =  EncodingUtil.base64Encode(encryptedData);
  	
   	strToken=strBase64Encoded;
  	//String strToken='+kxAl9B9uTSFlbOQHuayijgv1zBJNGVuZryI/ZdA8oGZW8vpikxUeYmJW/4pbC9uEn0qh3CbgqxNWUQseAYw/3vzAnTy1p8f/3ckzRyc08U=';
  	 String tokenUrlDecoded = EncodingUtil.urlDecode(strToken, 'UTF-8');
            tokenUrlDecoded = tokenUrlDecoded.replaceAll(' ', '+');
            Blob tokenDecodedBases64 = Encodingutil.base64Decode(tokenUrlDecoded);          
            Blob cryptoKey = Blob.valueOf('v7Y2g2webAqutAcr4DEC3uTAnaspEgA8');
            Blob initVector = Blob.valueof('da4atrABufastacr');
            // Decrypt the data
            Blob decryptedData = Crypto.decrypt('AES256', cryptoKey, initVector, tokenDecodedBases64);
            String tokenVal = decryptedData.toString();    
                // it is fixed for mul
          strContent=tokenVal;
          
          return strContent;
  	
  }*/
	public String getPageDetail(){
  		return ApexPages.currentPage().getUrl();
	}
  
	public Boolean getIsArticleDetailsPage(){
  		String pageURL=ApexPages.currentPage().getUrl();
	  	if(pageURL!=null && pageURL.indexOf('TOCArticleRendererPkb')>-1){
	  		return true;
	  	}
  		return false;
	}
	
	public String getURLProtocol(){
	 	return URL.getSalesforceBaseUrl().getProtocol();
	} 
  
	public String getCommunityId(){
   		String strReturnString='false';
   		for(Community objCommunity : [SELECT Id FROM Community WHERE Name = 'RingCentral Customer Community' limit 1 ]){
        	strReturnString=objCommunity.id;
    	}
   		return strReturnString;
   }
   
   /*********************************************************************************************
	* @Description : Method to redirect control to different pages.                              *
	* @Params      : void                                                                        * 
	* @Return      : void                                                                        * 
	*********************************************************************************************/
	public PageReference redirectToPage(){
		PageReference redirectToPage = null;
		try{
			String currentURL = URL.getCurrentRequestUrl().toExternalForm();
			system.debug('#### Current URL = '+currentURL);
			if(currentURL.contains('RCSupportPortalCreateNewCase')){
				currentURL = currentURL.replace('RCSupportPortalCreateNewCase','SupportPortalCaseCreate?pageid=contact');
			}
			if(currentURL.contains('RCContactSupp')){
				currentURL = currentURL.replace('RCContactSupp','SupportPortalContact?pageid=contact');
			}
			
			system.debug('#### Replaced Current URL = '+currentURL);
			
			if(currentURL.contains('btcloudphone')){
				//String newPage = 'https://box12-ringcentral.cs12.force.com/btcloudphone/SupportPortalHome';
				redirectToPage = new PageReference(currentURL);	
				redirectToPage.setRedirect(true);
				system.debug('#### Redirecting to Page = '+redirectToPage);
				return redirectToPage;
			}	
		}catch(Exception ex){
			system.debug('#### Exception at line = '+ex.getLineNumber()+' ,Exception Message = '+ex.getMessage());	
		}
		return redirectToPage;
	}
	
   /*public static  testmethod void myUnitTest(){
   	RCSupportControllerHandler objHandler=new RCSupportControllerHandler();
   	  Profile pp = [Select p.Name, p.Id From Profile p where Name LIKE '%RCSupport%'limit 1];
   	   User objUserGuest= new User(alias = 'ksTest',
	                                email='kanishk.singhTest@simplion.com',
	                                emailencodingkey='UTF-8',
	                                lastname='Testing',
	                                languagelocalekey='en_US',
	                                localesidkey='en_US',
	                                profileid = pp.id,
	                                timezonesidkey='America/Los_Angeles',
	                                username='kanishk.singhTest@simplion.com'
	                                );
	           insert objUserGuest;
   	
   	  system.runAs(objUserGuest){
   	  	objHandler=new RCSupportControllerHandler();
	     objHandler.showTabsDetail();
		 objHandler.updateUserProfile();
		 objHandler.validateLoginDetail();
		 objHandler.login();
		 objHandler.PageAuthorization();
		 objHandler.openCase();
		 objHandler.openMyCase();
		 objHandler.getPageDetail();
		 objHandler.getIsArticleDetailsPage();
		 objHandler.getURLProtocol();
		 objHandler.getNextPageName();
		 objHandler.getCommunityId();
   	  }
   	
   	 Account  objAccount= (Account  )SmartFactory.createSObject('Account', true);
	 upsert objAccount;
   	
   	   Contact objContact= (Contact)SmartFactory.createSObject('Contact', true);
	   objContact.AccountId=objAccount.id;
	   objContact.Email='kanishkTest@test.com';
	   objContact.FirstName='Kanishk';
	   upsert objContact;
   	
   	     User objUser = new User(alias = objContact.FirstName, 
                email=objContact.Email,  
                emailencodingkey='UTF-8', 
                lastname=objContact.LastName, 
                languagelocalekey='en_US', 
                localesidkey='en_US', 
                profileid= '00e80000001OK6k', //On production 'Sandbox 5:00e80000001OK6k',Production:00e80000001OK6k 
                contactId=objContact.id,
                timezonesidkey='America/Los_Angeles', 
                username= objContact.Email+system.Now().getTime(),
                CommunityNickname='User Community Nick name'+system.Now().getTime()
                ); 
                                                
                insert objUser;
   	
   
	 
	 
	 String strRandomPassword ='RC'+String.valueOf(Math.random());//'verity11'; //'RC'+String.valueOf(Math.random());
     system.setPassword(objUser.Id, strRandomPassword);
     String strToken = 'un=' + objUser.username + '&pw=' +  strRandomPassword;
     Blob cryptoKey = Blob.valueOf('v7Y2g2webAqutAcr4DEC3uTAnaspEgA8');
     Blob initVector = Blob.valueof('da4atrABufastacr');
     Blob data = Blob.valueOf(strToken);
     Blob encryptedData = Crypto.encrypt('AES256', cryptoKey, initVector, data);
    String strBase64Encoded =  EncodingUtil.base64Encode(encryptedData);
    //vauthUserInputParam.Out_Token = EncodingUtil.urlEncode(strBase64Encoded, 'UTF-8') + '#' + strBase64Encoded;
     
     String strTokenTest= strBase64Encoded; 
     String strNextPage='RCSupportPortalHomePage';
	 ApexPages.currentPage().getParameters().put('token',strTokenTest);
	 ApexPages.currentPage().getParameters().put('NEXTPAGE',strNextPage);
	 
	 objHandler=new RCSupportControllerHandler();
	 objHandler.showTabsDetail();
	 objHandler.updateUserProfile();
	 objHandler.validateLoginDetail();
	 objHandler.login();
	 objHandler.PageAuthorization();
	 objHandler.openCase();
	 objHandler.openMyCase();
	
	 objHandler.getPageDetail();
	 objHandler.getIsArticleDetailsPage();
	 objHandler.getURLProtocol();
	 objHandler.getCommunityId();
	 
	  ApexPages.currentPage().getParameters().put('startURL','/RCSupportPortalHome');
	  objHandler=new RCSupportControllerHandler();
	  objHandler.getNextPageName();
	 
	   system.runAs(objUserGuest){
	   	ApexPages.currentPage().getParameters().put('token',strTokenTest);
	    ApexPages.currentPage().getParameters().put('NEXTPAGE',strNextPage);
	    ApexPages.currentPage().getParameters().put('LCtabId','getting_a');
	    
	    objHandler=new RCSupportControllerHandler();
	     objHandler.validateLoginDetail();
	   	
	   }
	  PageReference objPageRef=new PageReference('http://success.ringcentral.com/knowledge/TOCArticleRendererPkb.apexp?id=kA2V00000008TK9');
	  objPageRef.setRedirect(true);
	  objHandler=new RCSupportControllerHandler();
	  objHandler.getIsArticleDetailsPage();
	}*/   
}// End of Class.
