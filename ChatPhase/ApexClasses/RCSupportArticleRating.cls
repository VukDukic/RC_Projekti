global class RCSupportArticleRating{

public Integer iArticleRatingCount{get;set;}
public Integer iArticleCount{get;set;}
public Integer iYourating{get;set;}
public String strArticleId{get;set;}
public Static String articleNumber{get;set;}
public String strUserId{get;set;}
public String IPAddress{get;set;}

public RCSupportArticleRating(){ 
  iArticleCount=0;
  articleNumber = '0'; 
  strArticleId=ApexPages.CurrentPage().getParameters().get('id');
  //IPAddress=ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');True-Client-IP
  IPAddress=ApexPages.currentPage().getHeaders().get('True-Client-IP');
  list<KnowledgeArticle> objKA = [SELECT Id,ArticleNumber FROM KnowledgeArticle WHERE Id =:strArticleId];
  
   if(objKA.size() >0 ){
  	articleNumber = String.valueOf(objKA[0].ArticleNumber);
  }
  system.debug('@@@@@@@@@@@'+articleNumber);
  IPAddress = (IPAddress == null || IPAddress == '' ? ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP') : IPAddress);
  
  for(RC_Article_Rating__c objRC_Article_Rating:[Select Article_Rating_Count__c,RC_Average_Rating__c from RC_Article_Rating__c where   
                                                     Article_Id__c=:strArticleId]){
  iArticleCount=Integer.valueOf(objRC_Article_Rating.RC_Average_Rating__c);

  }
    iYourating=0; 
   
   
    strUserId=null;
   // if(UserInfo.getName()!=(Site.getName()+' Site Guest User')){
       strUserId=UserInfo.getUserId();
        for(RC_User_Article_Rating__c objRCUser:[Select RC_Article_Rating__c from RC_User_Article_Rating__c where   
                                                       RC_ArticleID__c=:strArticleId and 
                                                       RC_User_Id__c=:UserInfo.getUserId() and IP_Address__c=:IPAddress]){
       iYourating=Integer.valueOf(objRCUser.RC_Article_Rating__c);
    }
       
       
    //}
  //strUserId=strArticleId;
   //strUserId=ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP'); 
   
}
public String getAuthToken()
    {
        String strToken = ApexPages.CurrentPage().getParameters().get('token');
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
         }
         if(strToken==''){
           strToken='false';
         }      
        return strToken;
   } 
 
 
 
 
 
 

webService static Integer articleCountSave2(Integer rating,String strArticleId,String IPAddress,String strComments,String strTitle){
    
   RC_Article_Rating__c objRC_Article_Rating = new RC_Article_Rating__c();
   RC_User_Article_Rating__c obUser = null;
   Integer iRating=0;
    try{
    	 iRating=rating; 
      try{
      	 List<KnowledgeArticle> objKA = [SELECT Id,ArticleNumber FROM KnowledgeArticle WHERE Id =:strArticleId];  
   		 if(objKA.size() >0 ){
  			articleNumber = String.valueOf(objKA[0].ArticleNumber); 
  		}
     
        objRC_Article_Rating=[Select RCCreatedById__c,RCCreatedByName__c,RCLastModifiedById__c,RCLastModifiedByName__c,Article_Number__c,
                              RCCreatedDate__c,RCLastModifiedDate__c,RCLastPublishedDate__c,RCFirstPublishedDate__c,Article_Rating_Count__c,
                              of_User_Rate_This_Article__c,RC_Average_Rating__c,Article_Id__c from RC_Article_Rating__c where   
                               Article_Id__c=:strArticleId];
                               
         objRC_Article_Rating.Article_Rating_Count__c =objRC_Article_Rating.Article_Rating_Count__c+rating;                     
         objRC_Article_Rating.of_User_Rate_This_Article__c=(objRC_Article_Rating.of_User_Rate_This_Article__c==null?0:objRC_Article_Rating.of_User_Rate_This_Article__c)+1;
         //objRC_Article_Rating.RC_Average_Rating__c=Math.round((objRC_Article_Rating.Article_Rating_Count__c/objRC_Article_Rating.of_User_Rate_This_Article__c));
         objRC_Article_Rating.RC_Average_Rating__c=(objRC_Article_Rating.Article_Rating_Count__c/objRC_Article_Rating.of_User_Rate_This_Article__c);
         iRating=rating; 
         rating=Integer.valueOf(objRC_Article_Rating.RC_Average_Rating__c);
         objRC_Article_Rating.article_Number__c = articleNumber;
         setArticleDetails(objRC_Article_Rating);
         system.debug('!!======!!'+articleNumber);
             
    }catch(Exception e){
        objRC_Article_Rating=new RC_Article_Rating__c(Article_Rating_Count__c=rating,Article_Id__c=strArticleId);
        objRC_Article_Rating.of_User_Rate_This_Article__c=1;
        objRC_Article_Rating.RC_Average_Rating__c=rating;
        objRC_Article_Rating.RCArticle_Title__c=strTitle;
        objRC_Article_Rating.article_Number__c = articleNumber;
        
        setArticleDetails(objRC_Article_Rating);     
      }
      
      upsert objRC_Article_Rating;
      
       obUser=new RC_User_Article_Rating__c();
        obUser.RC_Article_Rating__c=iRating;
        obUser.RC_ArticleID__c=strArticleId;
        obUser.RC_User_Id__c=UserInfo.getUserId();
        obUser.RC_Article_Rating_ID__c=objRC_Article_Rating.id;
        obUser.RC_User_name__c=UserInfo.getName();
        /*if(UserInfo.getName()==(Site.getName()+' Site Guest User')){
           obUser.RC_Rating_Type__c='Public';
        }else{
           obUser.RC_Rating_Type__c='Logged In';
        }*/
        obUser.RC_Rating_Type__c='Public';
        obUser.IP_Address__c=IPAddress;
        obUser.User_Comments__c=strComments;
        insert obUser;
     }catch(Exception e){
     rating=10;
   }
   //rating=Integer.valueOf(objRC_Article_Rating.Article_Rating_Count__c);
   //return rating;
   return rating;
   }
  public static void setArticleDetails(RC_Article_Rating__c objRC_Article_Rating){
     try{
       for(RC_Knowledge_Article__kav objRC_Knowledge_Article:[Select  r.Title,r.LastPublishedDate, r.LastModifiedDate, r.LastModifiedById, r.KnowledgeArticleId, r.FirstPublishedDate, r.Details__c, r.CurrencyIsoCode, r.CreatedDate,
                                                              r.CreatedById From RC_Knowledge_Article__kav r where PublishStatus='online' 
                                                              and KnowledgeArticleId=:objRC_Article_Rating.Article_Id__c limit 1]){
       
       objRC_Article_Rating.RCCreatedById__c=objRC_Knowledge_Article.CreatedById;
       objRC_Article_Rating.RCCreatedByName__c= getUsersName(objRC_Knowledge_Article.CreatedById);
       objRC_Article_Rating.RCLastModifiedById__c=objRC_Knowledge_Article.LastModifiedById;
       objRC_Article_Rating.RCLastModifiedByName__c=getUsersName(objRC_Knowledge_Article.LastModifiedById);
       objRC_Article_Rating.RCCreatedDate__c=objRC_Knowledge_Article.CreatedDate;
       objRC_Article_Rating.RCLastModifiedDate__c=objRC_Knowledge_Article.LastModifiedDate;
       objRC_Article_Rating.RCLastPublishedDate__c=objRC_Knowledge_Article.LastPublishedDate;
       objRC_Article_Rating.RCFirstPublishedDate__c=objRC_Knowledge_Article.FirstPublishedDate;
       objRC_Article_Rating.RCArticle_Title__c=objRC_Knowledge_Article.Title;      
       }
     }catch(Exception e){
       system.debug('>>>>>>'+e.getMessage());     
     }
  
   }
   public static String getUsersName(String id){
     String strname='';
       try{
           for(User u:[Select u.Name From User u where id=:id]){
               strname=u.Name;
           }
        }catch(Exception e){
           system.debug('>>>>>>'+e.getMessage());     
         }
      return strname;
   }
 
 
 
   
  
}
