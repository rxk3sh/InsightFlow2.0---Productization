/*******************************************************************************************************
* 
* @ Name    :   IFv2_TriggerHandlerTest
* @ Purpose :   Test data for Trigger handlers
* @ Author  :   Madhura Vani
* @ Class   :   IFv2_TriggerHandler
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*   15-01-2019      |  madhuravani.b@absyz.com      |  1.0          |  Initial Version
*   07-05-2019      |  vivek.kothalanka@absyz.com   |  1.0          |  updated code for  iteration 3
*
*******************************************************************************************************/

//Note : Used SeeAllData=true as we are using ConnectApi for chatter feed
@isTest(SeeAllData=true)
public class IFv2_TriggerHandlerTest {
    
    public static list<IFv2_Request__c> lstRequest ;
    public static Account objAcc;
    public static Contact objCon ; 
    public static User objUser;
    public static list<FeedItem> lstFeedItem; //holds feedItem
    
    public static testmethod void createTestData() {
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='JASONTest',
            Alias = 'jliv',
            Email = 'jason123.liveston@asdfe.com',
            Username = 'jason123.livestonAbsyz@asdfef.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
        
        
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason123.liveston@asdf.com',
                            Username = 'jason123.livestonAbsyz@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            iFreight_Approver_Level_2__c=user.id,
                            iFreight_Approver_Level_2_Proxy__c=user.id,
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        list<user> lstUserNew = new list<user>();
        lstUserNew.add(usr);
        insert lstUserNew;
        lstUserNew[0].Country = 'US';
        update lstUserNew[0];
        
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        System.RunAs(lstUser[0])
        {
            objExt.TotalOriginalValue__c = 0.00;
            insert objExt;
            IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
            insert objExt2;
            IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
            insert objExt3;
            lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
            lstRequest[0].Status__c = 'Draft' ;
            lstRequest[0].Workflow__c = 'eSignature'; 
            lstRequest[0].RequestExtension1__c = objExt.id;
            lstRequest[0].RequestExtension2__c = objExt2.id;
            lstRequest[0].RequestExtension3__c = objExt3.id;
            
            lstRequest[0].InformWhenApproved__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
            lstRequest[0].Approver1__c = UserInfo.getUserId();
            lstRequest[0].Approver2__c = UserInfo.getUserId();
            lstRequest[0].Approver3__c = UserInfo.getUserId();
            lstRequest[0].Approver4__c = UserInfo.getUserId();
            lstRequest[0].Approver5__c = UserInfo.getUserId();
            lstRequest[0].Approver6__c = UserInfo.getUserId();
            insert lstRequest ;
            objAcc = IFv2_testDataUtility.createAccount();
            insert objAcc;
            
            objCon = IFv2_testDataUtility.createContact(objAcc);
            insert objCon;
            
            //insert lstFeedItem;
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            // We can put the link and hashtag parts into a text segment to post the feed item. When it gets retrieved, it will have
            // separate segments for the text, link and hashtag.
            String expectedText = 'Text ';
            String expectedLink = 'http://link.com';
            String expectedHashtag = 'hashtag';
            String expectedBoldText = 'Bold text';
            
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            mentionSegmentInput.id = UserInfo.getUserId();
            messageBodyInput.messageSegments.add(mentionSegmentInput);
            
            ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
            markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupBeginSegmentInput);
            
            textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedBoldText;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
            markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupEndSegmentInput);
            
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = lstRequest[0].id;
            
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
            
            objAcc = [select id,name,Ifv2_request__c from Account limit 1];
            list<Account> lstAcc = new list<Account>();
            objAcc.Ifv2_request__c = lstRequest[0].id;
            objAcc.IFv2_OriginalValue__c = 5.00;
            objAcc.IFv2_NetBookValueatPlannedMonth__c = 6.00;
            lstAcc.add(objAcc);
            upsert lstAcc;
            
            objCon = [select id,lastname from Contact limit 1];
            
            IFv2_TriggerHandler objTriggerHandler = new IFv2_TriggerHandler();
            
            IFv2_TriggerHandler.sendEmailNotification(lstRequest,'Approved'); 
            IFv2_TriggerHandler.sendEmailNotification_Submit(lstRequest);
            IFv2_TriggerHandler.chatterSharingRecords([select id,body,NetworkScope,ParentId from feeditem where id=:feedElement.id]);
            map<id,id> mapIds = new map<id,id>();
            map<id,id> mapIds2 = new map<id,id>();
            IFv2_TriggerHandler.CreateExtensionShareRecords(lstRequest,mapIds,mapIds2);
            
            user oldUser = lstUserNew[0];
            Map<Id, User> mapUser = new Map<Id, User>();
            mapUser.put(oldUser.id, oldUser);
            
            lstUserNew[0].Country = 'China';
            try{
                IFv2_TriggerHandler.updatePermissionSets(lstUserNew,mapUser);
            }catch(Exception ex){
            }
            system.assertEquals('China',lstUserNew[0].Country);
            lstRequest[0].Workflow__C = 'China MAE Application - Combine';
            update lstRequest[0];
            system.assertEquals('China MAE Application - Combine',lstRequest[0].Workflow__C);
            objTriggerHandler.RollupSummaryDetails(lstAcc);
            ProcessInstanceWorkitem pworkItem = new ProcessInstanceWorkitem();
            list<id> lstIds = new list<id>();
            lstIds.add(objUser.id);
        }
        
    }
    
    //inserting the extension object 1
    static testmethod void createTestData1() {
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        insert objExt;
        
        lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
        lstRequest[0].Status__c = 'Draft' ;
        lstRequest[0].RequestExtension1__c = objExt.id;
        insert lstRequest[0];
        
        system.assertEquals('Draft', lstRequest[0].Status__c);
        map<id,id> mapIds = new map<id,id>();
        mapIds.put(lstRequest[0].id,objExt.id);
    }
    
    //inserting the extension object 2
    static testmethod void createTestData2() {
        IFv2_RequestExtension2__c objExt = new IFv2_RequestExtension2__c();
        insert objExt;
        
        lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
        lstRequest[0].Status__c = 'Draft' ;
        lstRequest[0].RequestExtension2__c = objExt.id;
        lstRequest[0].InformWhenApproved__c = UserInfo.getUserId();
        lstRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
        lstRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
        lstRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
        lstRequest[0].Approver1__c = UserInfo.getUserId();
        lstRequest[0].Approver2__c = UserInfo.getUserId();
        lstRequest[0].Approver3__c = UserInfo.getUserId();
        lstRequest[0].Approver4__c = UserInfo.getUserId();
        lstRequest[0].Approver5__c = UserInfo.getUserId();
        lstRequest[0].Approver6__c = UserInfo.getUserId();
        insert lstRequest[0];
        system.assertEquals('Draft', lstRequest[0].Status__c);
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        // We can put the link and hashtag parts into a text segment to post the feed item. When it gets retrieved, it will have
        // separate segments for the text, link and hashtag.
        String expectedText = 'Text ';
        String expectedLink = 'http://link.com';
        String expectedHashtag = 'hashtag';
        String expectedBoldText = 'Bold text';
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        mentionSegmentInput.id = UserInfo.getUserId();
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupBeginSegmentInput);
        
        textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedBoldText;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupEndSegmentInput);
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = lstRequest[0].id;
        
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        
        
        map<id,id> mapIds = new map<id,id>();
        mapIds.put(lstRequest[0].id,objExt.id);
        IFv2_TriggerHandler.chatterSharingRecords([select id,body,NetworkScope,ParentId from feeditem where id=:feedElement.id]);
        
    }
    
    static testmethod void createTestData3() {
        IFv2_RequestExtension3__c objExt = new IFv2_RequestExtension3__c();
        objExt.ProductionOrderNumber__c = 'Text';
        insert objExt;
        
        IFv2_RequestExtension1__c ext1= new IFv2_RequestExtension1__c();
        insert ext1;
        
        lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
        lstRequest[0].Status__c = 'Draft' ;
        lstRequest[0].RequestExtension3__c = objExt.id;
        lstRequest[0].InformWhenApproved__c = UserInfo.getUserId();
        lstRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
        lstRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
        lstRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
        lstRequest[0].Approver1__c = UserInfo.getUserId();
        lstRequest[0].Approver2__c = UserInfo.getUserId();
        lstRequest[0].Approver3__c = UserInfo.getUserId();
        lstRequest[0].Approver4__c = UserInfo.getUserId();
        lstRequest[0].Approver5__c = UserInfo.getUserId();
        lstRequest[0].Approver6__c = UserInfo.getUserId();
        // lstRequest[0].RequestExtension1__c = ext1.Id;
        insert lstRequest ;
        
        
        objAcc = IFv2_testDataUtility.createAccount();
        insert objAcc;
        
        objCon = IFv2_testDataUtility.createContact(objAcc);
        insert objCon;
        
        objUser = IFv2_testDataUtility.createUser();
        list<User> lstUser = new list<User>();
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = '';
        update lstUser[0];
        
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        // We can put the link and hashtag parts into a text segment to post the feed item. When it gets retrieved, it will have
        // separate segments for the text, link and hashtag.
        String expectedText = 'Text ';
        String expectedLink = 'http://link.com';
        String expectedHashtag = 'hashtag';
        String expectedBoldText = 'Bold text';
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        mentionSegmentInput.id = UserInfo.getUserId();
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupBeginSegmentInput);
        
        textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedBoldText;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupEndSegmentInput);
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = lstRequest[0].id;
        
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        
        objAcc = [select id,name,Ifv2_request__c from Account limit 1];
        list<Account> lstAcc = new list<Account>();
        objAcc.Ifv2_request__c = lstRequest[0].id;
        objAcc.IFv2_OriginalValue__c = 5.00;
        objAcc.IFv2_NetBookValueatPlannedMonth__c = 6.00;
        lstAcc.add(objAcc);
        upsert lstAcc;
        
        objCon = [select id,lastname from Contact limit 1];
        
        IFv2_TriggerHandler objTriggerHandler = new IFv2_TriggerHandler();
        
        IFv2_TriggerHandler.sendEmailNotification(lstRequest,'Approved'); 
        IFv2_TriggerHandler.sendEmailNotification(lstRequest,'Rejected');
        IFv2_TriggerHandler.sendEmailNotification_Submit(lstRequest);
        IFv2_TriggerHandler.chatterSharingRecords([select id,body,NetworkScope,ParentId from feeditem where id=:feedElement.id]);
        map<id,id> mapIds = new map<id,id>();
        mapIds.put(lstRequest[0].id,objExt.id);
        Map<String, String> mapDelegate=New Map<String,String>();
        mapDelegate.put(lstUser[0].Name,lstUser[0].Name);
        
        system.assertEquals(6.00, objAcc.IFv2_NetBookValueatPlannedMonth__c);
        set<id> setUserId=New Set<Id>();
        setUserId.add(lstUser[0].id);
        
        Map<Id, User> mapUser = new Map<Id, User>();
        mapUser.put(lstUser[0].id, lstUser[0]);
        try{
            IFv2_TriggerHandler.updatePermissionSets(lstUser,mapUser);
        }catch(Exception ex){
        }
        
        lstRequest[0].Workflow__C = 'China MAE Application - Combine';
        update lstRequest[0];
        objTriggerHandler.RollupSummaryDetails(lstAcc);
        
        ProcessInstanceWorkitem pworkItem = new ProcessInstanceWorkitem();
        IFv2_TriggerHandler.createReassignmentLog(pworkItem,lstUser[0].id,'China MAE Application - Combine',userInfo.getUserId());
        list<id> lstIds = new list<id>();
        lstIds.add(objUser.id);
        IFv2_TriggerHandler.assignRequestsBack(lstIds,'China MAE Application - Combine');
    }
    
    static testmethod void deligateApproverTest() {
        
        Test.startTest();
        
        User userRecord2;
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
            
            User userRecord = IFv2_testDataUtility.createSGStandardUser();
            userRecord.Username = 'testuserabsyz1@testabsyz.com';
            userRecord.Out_Of_Office__c = false;
            userRecord.Email = 'randomMail@test.com';
            insert userRecord;
            system.assertEquals('testuserabsyz1@testabsyz.com', userRecord.Username);
            
            userRecord2 = IFv2_testDataUtility.createSGStandardUser();
            userRecord2.Username = 'testuserabsyz2@testabsyz.com';
            userRecord2.Email = 'randomMail2@test.com';
            userRecord2.Out_Of_Office__c = false;
            insert userRecord2;
            
            userRecord2.Out_Of_Office__c = true;
            /* commented for destruction package
userRecord2.Delegate_eSignature__c = 'randomMail@test.com';
*/
            userRecord2.DelegatedApproverId = userRecord.Id;
            update userRecord2;
        }
        
        IFv2_Request__c eSignatureRequest = new IFv2_Request__c();
        eSignatureRequest.Workflow__c = 'eSignature';
        eSignatureRequest.Version__c = '1';
        eSignatureRequest.ReleaseDate__c = Date.today()+5;
        eSignatureRequest.Approver1__c =  userRecord2.Id;
        
        insert eSignatureRequest;
        IFv2_HeaderController.submitForApproval(eSignatureRequest,Null);
        
        Test.stopTest();
    }
    
    static testMethod void sendEmail() {
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        objExt.TotalOriginalValue__c = 0.00;
        insert objExt;
        contact testcontact = new contact();
        testcontact.lastname= 'testcontact';
        insert testcontact;
        IFv2_Request__c request =new IFv2_Request__c();
        
        insert request;
        lstRequest = [select id,InformWhenApproved__c,InformWhenApproved2__c,InformWhenApproved3__c,InformWhenApproved4__c from IFv2_Request__c limit 1];
        lstRequest[0].Status__c = 'Draft' ;
        lstRequest[0].RequestExtension1__c = objExt.id;
        lstRequest[0].InformWhenRejected__c = UserInfo.getUserId();
        lstRequest[0].InformWhenRejected2__c = UserInfo.getUserId();
        lstRequest[0].InformWhenRejected3__c = UserInfo.getUserId();
        lstRequest[0].InformWhenRejected4__c = UserInfo.getUserId();
        upsert lstRequest[0];
        system.assertEquals('Draft',lstRequest[0].Status__c);
        
    }
    
    Static testMethod Void insertAPACUser(){
        
        Test.startTest();
        user userrecord = IFv2_testDataUtility.createUser();
        userrecord.Username = 'testAdmin2@seg.com';
        userrecord.Country = 'China';
        insert userrecord;
        system.assertEquals('China',userrecord.country);
        
        Test.stopTest();
        
    }
    
    Static testMethod Void insertNALAUser(){
        
        Test.startTest();
        user userrecord = IFv2_testDataUtility.createUser();
        userrecord.Username = 'testAdmin2@seg.com';
        userrecord.Country = 'Brazil';
        insert userrecord;
        system.assertEquals('Brazil',userrecord.country);
        
        Test.stopTest();
        
    }
    
    Static testMethod Void insertEMEAUser(){
        
        Test.startTest();
        LIST<User> userList = new LIST<User>();
        
        User userrecord = IFv2_testDataUtility.createUser();
        userrecord.Username = 'testAdmin2@seg.com';
        userrecord.Country = 'Germany';
        userList.add(userrecord);
        
        User userrecord2 = IFv2_testDataUtility.createUser();
        userrecord2.Username = 'testAdmin3@seg.com';
        userrecord2.Country = 'Germany';
        userList.add(userrecord2);
        
        insert userList;
        system.assertEquals('Germany',userList[0].country);
        
        Test.stopTest();
        
    }
    
    Static testMethod void updateUserBrazil(){
        
        Test.startTest();
        User userRecord = IFv2_testDataUtility.createSGStandardUser();
        userRecord.Username = 'testuserabc@abc.com'+DateTime.now().getTime();
        userRecord.Country = 'Germany'; 
        insert userRecord;
        system.assertEquals('Germany',userRecord.country);
        
        IFv2_TriggerHandler.firstTime = true;
        User userRecord1 = [SELECT ID,Country FROM user where id=:userRecord.Id limit 1];
        userRecord1.Country = 'Brazil'; 
        update userRecord1;
        
        Test.stopTest();
    }
    
    public static testMethod void updateUserIndia(){
        
        Test.startTest();
        User userRecord = IFv2_testDataUtility.createSGStandardUser();
        userRecord.Username = 'testuserabsyz@abc.com'+DateTime.now().getTime();
        userRecord.isActive = true;
        userRecord.Country = 'Brazil';
        insert userRecord;
        
        system.assertEquals('Brazil',userRecord.country);
        User userRecord2 = IFv2_testDataUtility.createSGStandardUser();
        userRecord2.Username = 'testuserabsyz1@abc.com';
        userRecord2.isActive = true;
        userRecord2.Country = 'Brazil';
        insert userRecord2;
        system.assertEquals('Brazil',userRecord.country);
        test.stopTest();
        IFv2_TriggerHandler.firstTime = true;
        User userRecord1 = [SELECT ID,Country,isActive FROM user where id=:userRecord.Id limit 1];
        
        userRecord1.isActive = true;
        userRecord1.Country = 'China';
        update userRecord1;
        
        
    }
    
    Static testMethod void updateUserUSA(){
        
        Test.startTest();
        User userRecord = IFv2_testDataUtility.createSGStandardUser();
        userRecord.Username = 'testuserabc@abc.com'+DateTime.now().getTime();
        userRecord.Country = 'USA'; 
        insert userRecord;
        system.assertEquals('USA',userRecord.country);
        IFv2_TriggerHandler.firstTime = true;
        User userRecord1 = [SELECT ID,Country FROM user where id=:userRecord.Id limit 1];
        userRecord1.Country = 'Germany'; 
        update userRecord1;
        
        Test.stopTest();
    }
    
    Static testMethod void updateUserBulkData(){
        
        Test.startTest();
        User userRecord = IFv2_testDataUtility.createSGStandardUser();
        userRecord.Username = 'testuserabc@abc.com'+DateTime.now().getTime();
        userRecord.Country = 'USA'; 
        insert userRecord;
        system.assertEquals('USA',userRecord.country);
        User userRecord2 = IFv2_testDataUtility.createSGStandardUser();
        userRecord2.Username = 'testuserabcuser2@abc.com';
        userRecord2.Country = ' Mexico'; 
        insert userRecord2;
        
        IFv2_TriggerHandler.firstTime = true;
        LIST<User> userRecordLIST = new LIST<User>();
        LIST<User> userRecord1 = [SELECT ID,Country FROM user where id=:userRecord.Id ];
        for(User singleUser : userRecord1) {
            singleUser.Country = 'Germany';
            userRecordLIST.add(singleUser);
        }
        
        update userRecordLIST;
        Test.stopTest();
    }
    
    Public static testMethod void method2() {
        
        LIST<IFv2_Request__c> requestLIST = IFv2_testDataUtility.createRequest();
        map<id,id> mapIds = new map<id,id>();
        map<id,id> mapIds2 = new map<id,id>();
        IFv2_RequestExtension2__c extension2 = new IFv2_RequestExtension2__c();
        insert extension2;
        LIST<IFv2_Request__c> extLIST = new LIST<IFv2_Request__c>();
        for(IFv2_Request__c request : requestLIST) {
            
            request.Workflow__c = 'Predefined Workflow Approvals';
            request.RequestExtension2__c = extension2.Id;
            extLIST.add(request);
        }
        insert extLIST;
        system.assertEquals('Predefined Workflow Approvals',extLIST[0].Workflow__c);
        IFv2_TriggerHandler.CreateExtensionShareRecords(extLIST,mapIds,mapIds2);
        
    }
    
    Public static testMethod void method3() {
        
        LIST<IFv2_Request__c> requestLIST = IFv2_testDataUtility.createRequest();
        map<id,id> mapIds = new map<id,id>();
        map<id,id> mapIds2 = new map<id,id>();
        IFv2_RequestExtension3__c extension3 = new IFv2_RequestExtension3__c();
        insert extension3;
        LIST<IFv2_Request__c> extLIST = new LIST<IFv2_Request__c>();
        for(IFv2_Request__c request : requestLIST) {
            
            request.Workflow__c = 'Order experience Request';
            request.RequestExtension3__c = extension3.Id;
            extLIST.add(request);
        }
        insert extLIST;
        system.assertEquals('Order experience Request',extLIST[0].Workflow__c);
        IFv2_TriggerHandler.CreateExtensionShareRecords(extLIST,mapIds,mapIds2);
        
    }
    
    public static testMethod void method4(){
        
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        system.assertEquals('china',lstUser[0].Country);
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='JASONTest',
            Alias = 'jliv',
            Email = 'jason123.liveston@asdfe.com',
            Username = 'jason123.livestonAbsyz@asdfef.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
        
        
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason123.liveston@asdf.com',
                            Username = 'jason123.livestonAbsyz@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            iFreight_Approver_Level_2__c=user.id,
                            iFreight_Approver_Level_2_Proxy__c=user.id,
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        list<user> lstUserNew = new list<user>();
        lstUserNew.add(usr);
        insert lstUserNew;
        lstUserNew[0].Country = 'US';
        update lstUserNew[0];
        system.assertEquals('US',lstUserNew[0].Country);
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        System.RunAs(lstUser[0])
        {
            objExt.TotalOriginalValue__c = 0.00;
            insert objExt;
            IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
            insert objExt2;
            IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
            insert objExt3;
            lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
            lstRequest[0].Status__c = 'Draft' ;
            lstRequest[0].Workflow__c = 'Badge Management SEG - Stuttgart'; 
            lstRequest[0].RequestExtension1__c = objExt.id;
            lstRequest[0].RequestExtension2__c = objExt2.id;
            lstRequest[0].RequestExtension3__c = objExt3.id;
            
            lstRequest[0].InformWhenApproved__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
            lstRequest[0].Approver1__c = UserInfo.getUserId();
            lstRequest[0].Approver2__c = UserInfo.getUserId();
            lstRequest[0].Approver3__c = UserInfo.getUserId();
            lstRequest[0].Approver4__c = UserInfo.getUserId();
            lstRequest[0].Approver5__c = UserInfo.getUserId();
            lstRequest[0].Approver6__c = UserInfo.getUserId();
            insert lstRequest ;
            objAcc = IFv2_testDataUtility.createAccount();
            insert objAcc;
            
            objCon = IFv2_testDataUtility.createContact(objAcc);
            insert objCon;
            
            //insert lstFeedItem;
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            // We can put the link and hashtag parts into a text segment to post the feed item. When it gets retrieved, it will have
            // separate segments for the text, link and hashtag.
            String expectedText = 'Text ';
            String expectedLink = 'http://link.com';
            String expectedHashtag = 'hashtag';
            String expectedBoldText = 'Bold text';
            
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            mentionSegmentInput.id = UserInfo.getUserId();
            messageBodyInput.messageSegments.add(mentionSegmentInput);
            
            ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
            markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupBeginSegmentInput);
            
            textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedBoldText;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
            markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupEndSegmentInput);
            
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = lstRequest[0].id;
            
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
            
            objAcc = [select id,name,Ifv2_request__c from Account limit 1];
            list<Account> lstAcc = new list<Account>();
            objAcc.Ifv2_request__c = lstRequest[0].id;
            objAcc.IFv2_OriginalValue__c = 5.00;
            objAcc.IFv2_NetBookValueatPlannedMonth__c = 6.00;
            lstAcc.add(objAcc);
            upsert lstAcc;
            
            objCon = [select id,lastname from Contact limit 1];
            
            IFv2_TriggerHandler objTriggerHandler = new IFv2_TriggerHandler();
            
            IFv2_TriggerHandler.sendEmailNotification(lstRequest,'Approved'); 
            IFv2_TriggerHandler.sendEmailNotification_Submit(lstRequest);
            IFv2_TriggerHandler.chatterSharingRecords([select id,body,NetworkScope,ParentId from feeditem where id=:feedElement.id]);
            map<id,id> mapIds = new map<id,id>();
            map<id,id> mapIds2 = new map<id,id>();
            IFv2_TriggerHandler.CreateExtensionShareRecords(lstRequest,mapIds,mapIds2);
            
            user oldUser = lstUserNew[0];
            Map<Id, User> mapUser = new Map<Id, User>();
            mapUser.put(oldUser.id, oldUser);
            
            lstUserNew[0].Country = 'China';
            try{
                IFv2_TriggerHandler.updatePermissionSets(lstUserNew,mapUser);
            }catch(Exception ex){
            }
            
            lstRequest[0].Workflow__C = 'China MAE Application - Combine';
            update lstRequest[0];
            system.assertEquals('China MAE Application - Combine',lstRequest[0].Workflow__C);
            objTriggerHandler.RollupSummaryDetails(lstAcc);
            ProcessInstanceWorkitem pworkItem = new ProcessInstanceWorkitem();
            list<id> lstIds = new list<id>();
            lstIds.add(objUser.id);
        }
    }
    
    public static testMethod void method5(){
        
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        system.assertEquals('china',lstUser[0].Country);
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='JASONTest',
            Alias = 'jliv',
            Email = 'jason123.liveston@asdfe.com',
            Username = 'jason123.livest12onAbsyz@asdfef.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
        
        
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason123.liveston@asdf.com',
                            Username = 'jason123.lives12tonAbsyz@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            iFreight_Approver_Level_2__c=user.id,
                            iFreight_Approver_Level_2_Proxy__c=user.id,
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        list<user> lstUserNew = new list<user>();
        lstUserNew.add(usr);
        insert lstUserNew;
        lstUserNew[0].Country = 'US';
        update lstUserNew[0];
        system.assertEquals('US',lstUserNew[0].Country);
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        System.RunAs(lstUser[0])
        {
            objExt.TotalOriginalValue__c = 0.00;
            insert objExt;
            IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
            insert objExt2;
            IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
            insert objExt3;
            lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
            lstRequest[0].Status__c = 'Draft' ;
            lstRequest[0].Workflow__c = 'China Training Application'; 
            lstRequest[0].RequestExtension1__c = objExt.id;
            lstRequest[0].RequestExtension2__c = objExt2.id;
            lstRequest[0].RequestExtension3__c = objExt3.id;
            
            lstRequest[0].InformWhenApproved__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
            lstRequest[0].Approver1__c = UserInfo.getUserId();
            lstRequest[0].Approver2__c = UserInfo.getUserId();
            lstRequest[0].Approver3__c = UserInfo.getUserId();
            lstRequest[0].Approver4__c = UserInfo.getUserId();
            lstRequest[0].Approver5__c = UserInfo.getUserId();
            lstRequest[0].Approver6__c = UserInfo.getUserId();
            insert lstRequest ;
            objAcc = IFv2_testDataUtility.createAccount();
            insert objAcc;
            
            objCon = IFv2_testDataUtility.createContact(objAcc);
            insert objCon;
            
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            // We can put the link and hashtag parts into a text segment to post the feed item. When it gets retrieved, it will have
            // separate segments for the text, link and hashtag.
            String expectedText = 'Text ';
            String expectedLink = 'http://link.com';
            String expectedHashtag = 'hashtag';
            String expectedBoldText = 'Bold text';
            
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            mentionSegmentInput.id = UserInfo.getUserId();
            messageBodyInput.messageSegments.add(mentionSegmentInput);
            
            ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
            markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupBeginSegmentInput);
            
            textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedBoldText;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
            markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupEndSegmentInput);
            
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = lstRequest[0].id;
            
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
            
            objAcc = [select id,name,Ifv2_request__c from Account limit 1];
            list<Account> lstAcc = new list<Account>();
            objAcc.Ifv2_request__c = lstRequest[0].id;
            objAcc.IFv2_OriginalValue__c = 5.00;
            objAcc.IFv2_NetBookValueatPlannedMonth__c = 6.00;
            lstAcc.add(objAcc);
            upsert lstAcc;
            
            objCon = [select id,lastname from Contact limit 1];
            
            IFv2_TriggerHandler objTriggerHandler = new IFv2_TriggerHandler();
            
            IFv2_TriggerHandler.sendEmailNotification(lstRequest,'Approved'); 
            IFv2_TriggerHandler.sendEmailNotification_Submit(lstRequest);
            IFv2_TriggerHandler.chatterSharingRecords([select id,body,NetworkScope,ParentId from feeditem where id=:feedElement.id]);
            map<id,id> mapIds = new map<id,id>();
            map<id,id> mapIds2 = new map<id,id>();
            IFv2_TriggerHandler.CreateExtensionShareRecords(lstRequest,mapIds,mapIds2);
            
            user oldUser = lstUserNew[0];
            Map<Id, User> mapUser = new Map<Id, User>();
            mapUser.put(oldUser.id, oldUser);
            
            lstUserNew[0].Country = 'China';
            try{
                IFv2_TriggerHandler.updatePermissionSets(lstUserNew,mapUser);
            }catch(Exception ex){
            }
            
            lstRequest[0].Workflow__C = 'China MAE Application - Combine';
            update lstRequest[0];
            objTriggerHandler.RollupSummaryDetails(lstAcc);
            ProcessInstanceWorkitem pworkItem = new ProcessInstanceWorkitem();
            list<id> lstIds = new list<id>();
            system.assertEquals('China MAE Application - Combine',lstRequest[0].Workflow__C);
            lstIds.add(objUser.id);
        }
    }
    
    public static testMethod void method6(){
        
        
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='JASONTest',
            Alias = 'jliv',
            Email = 'jason123.liveston@asdfe.com',
            Username = 'jason123.livest12onAbsyz@asdfef.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
        
        
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason123.liveston@asdf.com',
                            Username = 'jason123.lives12tonAbsyz@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            iFreight_Approver_Level_2__c=user.id,
                            iFreight_Approver_Level_2_Proxy__c=user.id,
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        list<user> lstUserNew = new list<user>();
        lstUserNew.add(usr);
        insert lstUserNew;
        lstUserNew[0].Country = 'US';
        update lstUserNew[0];
        
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        System.RunAs(lstUser[0])
        {
            objExt.TotalOriginalValue__c = 0.00;
            insert objExt;
            IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
            insert objExt2;
            IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
            insert objExt3;
            lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
            lstRequest[0].Status__c = 'Draft' ;
            lstRequest[0].Workflow__c = 'Predefined Workflow Approvals'; 
            lstRequest[0].RequestExtension1__c = objExt.id;
            lstRequest[0].RequestExtension2__c = objExt2.id;
            lstRequest[0].RequestExtension3__c = objExt3.id;
            
            lstRequest[0].InformWhenApproved__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
            lstRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
            lstRequest[0].Approver1__c = UserInfo.getUserId();
            lstRequest[0].Approver2__c = UserInfo.getUserId();
            lstRequest[0].Approver3__c = UserInfo.getUserId();
            lstRequest[0].Approver4__c = UserInfo.getUserId();
            lstRequest[0].Approver5__c = UserInfo.getUserId();
            lstRequest[0].Approver6__c = UserInfo.getUserId();
            insert lstRequest ;
            objAcc = IFv2_testDataUtility.createAccount();
            insert objAcc;
            
            objCon = IFv2_testDataUtility.createContact(objAcc);
            insert objCon;
            
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            // We can put the link and hashtag parts into a text segment to post the feed item. When it gets retrieved, it will have
            // separate segments for the text, link and hashtag.
            String expectedText = 'Text ';
            String expectedLink = 'http://link.com';
            String expectedHashtag = 'hashtag';
            String expectedBoldText = 'Bold text';
            
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            mentionSegmentInput.id = UserInfo.getUserId();
            messageBodyInput.messageSegments.add(mentionSegmentInput);
            
            ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
            markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupBeginSegmentInput);
            
            textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = expectedBoldText;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
            markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
            messageBodyInput.messageSegments.add(markupEndSegmentInput);
            
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = lstRequest[0].id;
            
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
            
            objAcc = [select id,name,Ifv2_request__c from Account limit 1];
            list<Account> lstAcc = new list<Account>();
            objAcc.Ifv2_request__c = lstRequest[0].id;
            objAcc.IFv2_OriginalValue__c = 5.00;
            objAcc.IFv2_NetBookValueatPlannedMonth__c = 6.00;
            lstAcc.add(objAcc);
            upsert lstAcc;
            
            objCon = [select id,lastname from Contact limit 1];
            
            IFv2_TriggerHandler objTriggerHandler = new IFv2_TriggerHandler();
            
            IFv2_TriggerHandler.sendEmailNotification(lstRequest,'Approved'); 
            IFv2_TriggerHandler.sendEmailNotification_Submit(lstRequest);
            IFv2_TriggerHandler.chatterSharingRecords([select id,body,NetworkScope,ParentId from feeditem where id=:feedElement.id]);
            map<id,id> mapIds = new map<id,id>();
            map<id,id> mapIds2 = new map<id,id>();
            IFv2_TriggerHandler.CreateExtensionShareRecords(lstRequest,mapIds,mapIds2);
            
            user oldUser = lstUserNew[0];
            Map<Id, User> mapUser = new Map<Id, User>();
            mapUser.put(oldUser.id, oldUser);
            
            lstUserNew[0].Country = 'China';
            try{
                IFv2_TriggerHandler.updatePermissionSets(lstUserNew,mapUser);
            }catch(Exception ex){
            }
            
            lstRequest[0].Workflow__C = 'China MAE Application - Combine';
            update lstRequest[0];
            objTriggerHandler.RollupSummaryDetails(lstAcc);
            system.assertEquals('China MAE Application - Combine',lstRequest[0].Workflow__C);
            ProcessInstanceWorkitem pworkItem = new ProcessInstanceWorkitem();
            list<id> lstIds = new list<id>();
            lstIds.add(objUser.id);
        }
    }
    
    public static testMethod void getRequest(){
        
        Account testAccount = new Account();
        testAccount.name  = 'test';
        insert testAccount;
        LIST<IFv2_Request__c> requstLIST =  Ifv2_testDataUtility.createRequest();
        for(IFv2_Request__c request :requstLIST){
            request.Workflow__c = 'Concession';
            request.Account__c = testAccount.Id;
        }
        Insert requstLIST;
        testAccount.IFv2_SAPUPDATERESULT__c = 'test';
        update testAccount;
        system.assertEquals('test',testAccount.IFv2_SAPUPDATERESULT__c);
        LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
        for(IFv2_Request__c requestupdate :requstLIST){
            requestupdate.Status__c = 'Approved';
            requestupdate.ArchivalStatus__c = 'Fail';
            requestLIST.add(requestupdate);
        }
        update requestLIST;
    }
    
    public static testMethod void getRequestRejeceted(){
        
        Account testAccount = new Account();
        testAccount.name  = 'test';
        insert testAccount;
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 0;
        objWF.SubsequentReminderAfter__c = 0;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        
        LIST<IFv2_Request__c> requstLIST =  Ifv2_testDataUtility.createRequest();
        for(IFv2_Request__c request :requstLIST){
            request.Workflow__c = 'eSignature';
            request.Account__c = testAccount.Id;
        }
        Insert requstLIST;
        testAccount.IFv2_SAPUPDATERESULT__c = 'test';
        update testAccount;
        system.assertEquals('test',testAccount.IFv2_SAPUPDATERESULT__c);
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(requstLIST[0].Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_eSignature');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        system.assertEquals(true,result.isSuccess());
        
        LIST<IFv2_Request__c> requestLIST = new LIST<IFv2_Request__c>();
        for(IFv2_Request__c requestupdate :requstLIST){
            requestupdate.Status__c = 'Rejected';
            requestupdate.ArchivalStatus__c = 'Fail';
            requestLIST.add(requestupdate);
        }
        update requestLIST;
    }
    
    public static testMethod void deleteScanMethod() {
        test.startTest();
        LIST<Scan__c> scanRecordsLIST = IFv2_testDataUtility.createScanRecord(2);
        insert scanRecordsLIST;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = blob.valueof('Test Content Data'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        system.assertEquals(true, contentVersionSelect!= NULL);
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentVersionSelect.ContentDocumentId limit 1];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=scanRecordsLIST[0].id; 
        contentlink.ShareType= 'V';              
        contentlink.ContentDocumentId=documents[0].Id;
        insert contentlink;
        
        MAP<Id, Scan__c> scanIdMap = new MAP<Id,Scan__c>();
        for(Scan__c scan: scanRecordsLIST) {
            scanIdMap.put(scan.Id, scan);
        }
        IFv2_TriggerHandler.deleteScanRelatedRecords(scanIdMap);
        
        
        test.stopTest();
    }
    
    public static testMethod void deleteRelatedRequestMethod() {
        test.startTest();
        
        IFv2_RequestExtension2__c ext2 = new IFv2_RequestExtension2__c();
        insert ext2;
        
        LIST<IFv2_Request__c> requestRecordsLIST = IFv2_testDataUtility.createRequest();
        requestRecordsLIST[0].Workflow__c = 'Predefined Workflow Approvals';
        requestRecordsLIST[0].RequestExtension2__c = ext2.Id;
        insert requestRecordsLIST;
        System.assertEquals('Predefined Workflow Approvals', requestRecordsLIST[0].Workflow__c );
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = blob.valueof('Test Content Data'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument limit 1];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=requestRecordsLIST[0].id; 
        contentlink.ShareType= 'V';              
        contentlink.ContentDocumentId=documents[0].Id;
        insert contentlink;
        try{
            delete requestRecordsLIST;
        } catch(Exception e){
            
        }
        
        
        
        test.stopTest();
    }
    
    public static testMethod void deleteRelatedRequestMethod2() {
        test.startTest();
        
        IFv2_RequestExtension3__c ext3 = new IFv2_RequestExtension3__c();
        insert ext3;
        
        LIST<IFv2_Request__c> requestRecordsLIST2 = IFv2_testDataUtility.createRequest();
        requestRecordsLIST2[0].Workflow__c = 'Requests for corporate card';
        requestRecordsLIST2[0].RequestExtension3__c = ext3.Id;
        insert requestRecordsLIST2;
        System.assertEquals('Requests for corporate card', requestRecordsLIST2[0].Workflow__c );
        
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = blob.valueof('Test Content Data'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument limit 1];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=requestRecordsLIST2[0].id; 
        contentlink.ShareType= 'V';              
        contentlink.ContentDocumentId=documents[0].Id;
        insert contentlink;
        
        try{
            delete requestRecordsLIST2;
        }  catch(Exception e){
            
        }
        
        
        
        test.stopTest();
    } 
    
    public static testMethod void deleteRelatedRequestMethod3() {
        test.startTest();
        
        Account acountInsert = new Account();
        acountInsert.name = 'test';
        acountInsert.Plant__c ='SGHU';
        insert acountInsert;
        
        LIST<IFv2_Request__c> requestRecordsLIST2 = IFv2_testDataUtility.createRequest();
        requestRecordsLIST2[0].Workflow__c = 'eSignature';
        requestRecordsLIST2[0].Account__c = acountInsert.Id;
        insert requestRecordsLIST2;
        System.assertEquals('eSignature', requestRecordsLIST2[0].Workflow__c );
        
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = blob.valueof('Test Content Data'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument limit 1];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=requestRecordsLIST2[0].id; 
        contentlink.ShareType= 'V';              
        contentlink.ContentDocumentId=documents[0].Id;
        insert contentlink;
        
        delete requestRecordsLIST2;
        
        
        test.stopTest();
    }
    
    public static testMethod void chatterCommentAccessMethod(){
        String communityId = Network.getNetworkId();
        //String feedElementId = '0D5D0000000KtW3';
        list<IFv2_Request__c> lstRequest ;
        lstRequest = IFv2_testDataUtility.createRequest();  //inserting Request 
        insert lstRequest ;
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        // We can put the link and hashtag parts into a text segment to post the feed item. When it gets retrieved, it will have
        // separate segments for the text, link and hashtag.
        String expectedText = 'Text ';
        String expectedLink = 'http://link.com';
        String expectedHashtag = 'hashtag';
        String expectedBoldText = 'Bold text';
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        mentionSegmentInput.id = UserInfo.getUserId();
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupBeginSegmentInput);
        
        textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedBoldText;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupEndSegmentInput);
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = lstRequest[0].id;
        
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(communityId, feedItemInput);
        
        ConnectApi.CommentInput commentInput = new ConnectApi.CommentInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput2 = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput2 = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
        
        messageBodyInput2.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        textSegmentInput2.text = 'Does anyone in this group have an idea? ';
        messageBodyInput2.messageSegments.add(textSegmentInput2);
        
        mentionSegmentInput2.id = UserInfo.getUserId();
        messageBodyInput2.messageSegments.add(mentionSegmentInput2);
        
        commentInput.body = messageBodyInput2;
        
        ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(communityId, feedElement.Id, commentInput, null);
    }
    
    public static testMethod void requestAccessForUpdatedDelegateUsersTest()
    {
        test.startTest();
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='JASONTest',
            Alias = 'jliv',
            Email = 'jason123.liveston@asdfe.com',
            Username = 'jason123.livestonAbsyz@asdfef.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
        MAP<Id, User> oldMap=new MAP<Id,User>();
        user.DelegatedApproverId=user.Id;
        oldMap.put(user.Id,user);
        User user2= [Select Id,name,DelegatedApproverId from user where email='jason123.liveston@asdfe.com' limit 1];
        user2.DelegatedApproverId=user.Id;
        MAP<Id, User> newMap=new MAP<Id,User>();
        newMap.put(user2.id,user2);
        
        SET<Id> userIdSET = new SET<Id>();
        userIdSET.add(user.id);
        LIST<ProcessInstanceWorkitem> proWorkItemLIST = new  LIST<ProcessInstanceWorkitem>();
        String soqlProWork = 'SELECT Id, ActorId, ProcessInstanceId, p.ProcessInstance.TargetObject.Name,'; 
        soqlProWork += ' p.ProcessInstance.TargetObjectId '; 
        soqlProWork += ' FROM ProcessInstanceWorkItem p ';
        soqlProWork += ' WHERE ( ';
        //    soqlProWork += ' ActorId = : userIdSET '; 
        //    soqlProWork += ') ';
        //    soqlProWork += ' AND (';
        soqlProWork += ' p.ProcessInstance.Status = \'Pending\' ';
        //soqlProWork += ' OR p.ProcessInstance.Status != \'Rejected\' ';
        soqlProWork += ')';
        soqlProWork += ' Order By CreatedDate Desc ';
        proWorkItemLIST = Database.query(soqlProWork);
        System.debug('proWorkItemLIST>>'+proWorkItemLIST);
        
        IFv2_TriggerHandler.requestAccessForUpdatedDelegateUsers(oldMap,newMap);
        test.stopTest();
    }
    
    public static testMethod void sendEmailsToNewDelegatedApproverTest()
    {
        Id userId=Userinfo.getUserId();
        test.startTest();
        MAP<Id, LIST<IFv2_Request__c>> delegateIdRequestListMAP=new MAP<Id,LIST<IFv2_Request__c>>();
        LIST<IFv2_Request__c> requestList=new List<IFv2_Request__c>();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        //testAccount.IFv2_ShortDescription__c = 'Test Description';
        insert testAccount;
        IFv2_Request__c r = new IFv2_Request__c();
        r.Status__c = 'Draft';
        r.Workflow__c = 'eSignature';
        r.Account__c = testAccount.Id;
        insert r;
        requestList.add(r);
        delegateIdRequestListMAP.put(userId,requestLIST);        
        
        User userRecord=[select id,name,DelegatedApproverId,email from User where id=:userId];
        MAP<Id, User> userDetailsMAP=new MAP<Id,User>();
        userDetailsMAP.put(userId,userRecord);
        
        MAP<Id, Id> delegateUserMAP=new MAP<Id, Id>();
        delegateUserMAP.put(userId,userId);
        IFv2_TriggerHandler.sendEmailsToNewDelegatedApprover(delegateIdRequestListMAP,userDetailsMAP,delegateUserMAP);
        
        test.stopTest();
    }
    
    public static testMethod void recordShareForDelegatedApproverTest()
    {
        test.startTest();
        SET<Id> delegateUserIdSET=new SET<Id>();
        delegateUserIdSET.add(Userinfo.getUserId());
        LIST<IFv2_Request__c> requestList=new List<IFv2_Request__c>();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        objExt.TotalOriginalValue__c = 0.00;
        insert objExt;
        
        
        insert testAccount;
        IFv2_Request__c r = new IFv2_Request__c();
        r.Status__c = 'Draft';
        r.Workflow__c = 'eSignature';
        r.Account__c = testAccount.Id;
        r.RequestExtension1__c=objExt.id;
        insert r;
        requestList.add(r);
        
        String jsonRequest=JSON.serialize(r);
        System.debug('jsonRequest>'+jsonRequest);
        IFv2_TriggerHandler.recordShareForDelegatedApprover(delegateUserIdSET,jsonRequest);
        
        IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
        insert objExt2;
        IFv2_Request__c requestRecord = new IFv2_Request__c();
        requestRecord.Status__c = 'Draft';
        requestRecord.Workflow__c = 'eSignature';
        requestRecord.Account__c = testAccount.Id;
        requestRecord.RequestExtension2__c=objExt2.id;
        insert requestRecord;       
        String jsonRequest2=JSON.serialize(requestRecord);
        System.debug('jsonRequest>'+jsonRequest2);
        IFv2_TriggerHandler.recordShareForDelegatedApprover(delegateUserIdSET,jsonRequest2);
        
        IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
        insert objExt3;
        IFv2_Request__c requestRecord3 = new IFv2_Request__c();
        requestRecord3.Status__c = 'Draft';
        requestRecord3.Workflow__c = 'eSignature';
        requestRecord3.Account__c = testAccount.Id;
        requestRecord3.RequestExtension3__c=objExt3.id;
        insert requestRecord3;       
        String jsonRequest3=JSON.serialize(requestRecord3);
        System.debug('jsonRequest>'+jsonRequest3);
        IFv2_TriggerHandler.recordShareForDelegatedApprover(delegateUserIdSET,jsonRequest3);
        
        
        test.stopTest();
    }
    
    static testmethod void SubmittedApproverChange() {
        User userRecord1=[select id,name from User limit 1];
        Id userId1;
        if(userRecord1!=null)
            userId1=userRecord1.id;
        SET<Id> delegateUserIdSET=new SET<Id>();
        delegateUserIdSET.add(Userinfo.getUserId());
        LIST<IFv2_Request__c> requestList=new List<IFv2_Request__c>();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        /*
IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
objExt.TotalOriginalValue__c = 0.00;
insert objExt;
*/
        
        insert testAccount;
        
        IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
        insert objExt2;
        
        IFv2_RequestExtension1__c objExt1 = new IFv2_RequestExtension1__c();
        insert objExt1;
        
        IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
        insert objExt3;
        IFv2_Request__c requestRecord3 = new IFv2_Request__c();
        requestRecord3.Status__c = 'Submitted';
        requestRecord3.Workflow__c = 'eSignature';
        requestRecord3.Account__c = testAccount.Id;
        requestRecord3.RequestExtension1__c=objExt1.id;
        requestRecord3.RequestExtension3__c=objExt3.id;
        requestRecord3.RequestExtension2__c=objExt2.id;
        requestRecord3.Approver1__c=Userinfo.getUserId();
        requestRecord3.Approver2__c=Userinfo.getUserId();
        insert requestRecord3; 
        
        IFv2_Request__c requestRecord4 = new IFv2_Request__c();
        requestRecord4.Status__c = 'Submitted';
        requestRecord4.Workflow__c = 'China Travel Application';
        requestRecord4.Account__c = testAccount.Id;
        requestRecord4.RequestExtension1__c=objExt1.id;
        requestRecord4.RequestExtension3__c=objExt3.id;
        requestRecord4.RequestExtension2__c=objExt2.id;
        requestRecord4.Approver1__c=Userinfo.getUserId();
        requestRecord4.Approver2__c=Userinfo.getUserId();
        insert requestRecord4; 
        
        
        IFv2_Request__c requestRecord5 = new IFv2_Request__c();
        requestRecord5.Status__c = 'Submitted';
        requestRecord5.Workflow__c = 'Overtime Request';
        requestRecord5.Account__c = testAccount.Id;
        requestRecord5.RequestExtension1__c=objExt1.id;
        requestRecord5.RequestExtension3__c=objExt3.id;
        requestRecord5.RequestExtension2__c=objExt2.id;
        requestRecord5.Approver1__c=Userinfo.getUserId();
        requestRecord5.Approver2__c=Userinfo.getUserId();
        insert requestRecord5;
        
        IFv2_Request__c requestRecord6 = new IFv2_Request__c();
        requestRecord6.Status__c = 'Submitted';
        requestRecord6.Workflow__c = 'Employee Suggestion Scheme US MX';
        requestRecord6.Account__c = testAccount.Id;
        requestRecord6.RequestExtension1__c=objExt1.id;
        requestRecord6.RequestExtension3__c=objExt3.id;
        requestRecord6.RequestExtension2__c=objExt2.id;
        requestRecord6.Approver1__c=Userinfo.getUserId();
        requestRecord6.Approver2__c=Userinfo.getUserId();
        insert requestRecord6; 
        
        IFv2_Request__c requestRecord7 = new IFv2_Request__c();
        requestRecord7.Status__c = 'Submitted';
        requestRecord7.Workflow__c = 'Overtime Request Germany';
        requestRecord7.Account__c = testAccount.Id;
        requestRecord7.RequestExtension1__c=objExt1.id;
        requestRecord7.RequestExtension3__c=objExt3.id;
        requestRecord7.RequestExtension2__c=objExt2.id;
        requestRecord7.Approver1__c=Userinfo.getUserId();
        requestRecord7.Approver2__c=Userinfo.getUserId();
        insert requestRecord7; 
        
        
        test.startTest();
        requestRecord3.RequestExtension3__c=objExt3.id;
        requestRecord3.Approver2__c=Userinfo.getUserId();
        requestRecord3.Approver3__c=Userinfo.getUserId();
        requestRecord3.Approver4__c=userId1;
        requestRecord3.Approver5__c=Userinfo.getUserId();
        requestRecord3.Approver6__c=Userinfo.getUserId();
        requestRecord3.Approver7__c=Userinfo.getUserId();
        requestRecord3.Approver8__c=Userinfo.getUserId();
        requestRecord3.Approver9__c=Userinfo.getUserId();
        requestRecord3.Approver10__c=Userinfo.getUserId();
        requestRecord3.Approver11__c=Userinfo.getUserId();
        requestRecord3.Approver12__c=Userinfo.getUserId();
        requestRecord3.Approver13__c=Userinfo.getUserId();
        requestRecord3.Approver14__c=Userinfo.getUserId();
        requestRecord3.Approver15__c=Userinfo.getUserId();
        requestRecord3.Approver16__c=Userinfo.getUserId();
        requestRecord3.Approver17__c=Userinfo.getUserId();
        requestRecord3.Approver18__c=Userinfo.getUserId();
        requestRecord3.Approver19__c=Userinfo.getUserId();
        requestRecord3.Approver20__c=Userinfo.getUserId();
        requestRecord3.Approver21__c=Userinfo.getUserId();
        requestRecord3.Approver22__c=Userinfo.getUserId();
        requestRecord3.Approver23__c=Userinfo.getUserId();
        requestRecord3.Approver24__c=Userinfo.getUserId();
        requestRecord3.Approver25__c=Userinfo.getUserId();
        update requestRecord3;
        
        requestRecord4.Approver2__c=Userinfo.getUserId();
        requestRecord4.Approver3__c=Userinfo.getUserId();
        requestRecord4.Approver4__c=userId1;
        update requestRecord4;
        
        requestRecord5.Approver2__c=Userinfo.getUserId();
        requestRecord5.Approver3__c=Userinfo.getUserId();
        requestRecord5.Approver4__c=userId1;
        update requestRecord5;
        
        requestRecord6.Approver2__c=Userinfo.getUserId();
        requestRecord6.Approver3__c=Userinfo.getUserId();
        requestRecord6.Approver4__c=userId1;
        update requestRecord6;
        
        requestRecord7.Approver2__c=Userinfo.getUserId();
        requestRecord7.Approver3__c=Userinfo.getUserId();
        requestRecord7.Approver4__c=userId1;
        update requestRecord7;
        
        test.stopTest();
    }
    
    static testmethod void SubmittedApproverChangeRevokeAccess() {
        User userRecord1=[select id,name from User limit 1];
        Id userId1;
        if(userRecord1!=null)
            userId1=userRecord1.id;
        User userRecord2=[select id,name from User limit 1];
        Id userId2;
        if(userRecord2!=null)
            userId2=userRecord2.id;
        SET<Id> delegateUserIdSET=new SET<Id>();
        delegateUserIdSET.add(Userinfo.getUserId());
        LIST<IFv2_Request__c> requestList=new List<IFv2_Request__c>();
        
        Account testAccount = new Account();
        testAccount.name = 'test';
        /*
IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
objExt.TotalOriginalValue__c = 0.00;
insert objExt;
*/
        
        insert testAccount;
        
        IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
        insert objExt2;
        IFv2_RequestExtension1__c objExt1 = new IFv2_RequestExtension1__c();
        insert objExt1;
        
        IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
        insert objExt3;
        IFv2_Request__c requestRecord3 = new IFv2_Request__c();
        requestRecord3.Status__c = 'Submitted';
        requestRecord3.Workflow__c = 'eSignature';
        requestRecord3.Account__c = testAccount.Id;
        requestRecord3.RequestExtension3__c=objExt3.id;
        requestRecord3.Approver1__c=userId1;
        requestRecord3.Approver2__c=Userinfo.getUserId();
        requestRecord3.Approver3__c=userId1;
        requestRecord3.Approver4__c=userId1;
        requestRecord3.Approver5__c=userId1;
        requestRecord3.Approver6__c=userId1;
        requestRecord3.Approver7__c=userId1;
        requestRecord3.Approver8__c=userId1;
        requestRecord3.Approver9__c=userId1;
        requestRecord3.Approver10__c=userId1;
        requestRecord3.Approver11__c=userId1;
        requestRecord3.Approver12__c=userId1;
        requestRecord3.Approver13__c=userId1;
        requestRecord3.Approver14__c=userId1;
        requestRecord3.Approver15__c=userId1;
        requestRecord3.Approver16__c=userId1;
        requestRecord3.Approver17__c=userId1;
        requestRecord3.Approver18__c=userId1;
        requestRecord3.Approver19__c=userId1;
        requestRecord3.Approver20__c=userId1;
        requestRecord3.Approver21__c=userId1;
        requestRecord3.Approver22__c=userId1;
        requestRecord3.Approver23__c=userId1;
        requestRecord3.Approver24__c=userId1;
        requestRecord3.Approver25__c=userId1;
        insert requestRecord3;       
        
        test.startTest();
        requestRecord3.Approver2__c=userId2;
        requestRecord3.Approver3__c=userId2;
        requestRecord3.Approver4__c=userId2;
        requestRecord3.Approver5__c=userId2;
        requestRecord3.Approver6__c=userId2;
        requestRecord3.Approver7__c=userId2;
        requestRecord3.Approver8__c=userId2;
        requestRecord3.Approver9__c=userId2;
        requestRecord3.Approver10__c=userId2;
        requestRecord3.Approver11__c=userId2;
        requestRecord3.Approver12__c=userId2;
        requestRecord3.Approver13__c=userId2;
        requestRecord3.Approver14__c=userId2;
        requestRecord3.Approver15__c=userId2;
        requestRecord3.Approver16__c=userId2;
        requestRecord3.Approver17__c=userId2;
        requestRecord3.Approver18__c=userId2;
        requestRecord3.Approver19__c=userId2;
        requestRecord3.Approver20__c=userId2;
        requestRecord3.Approver21__c=userId2;
        requestRecord3.Approver22__c=userId2;
        requestRecord3.Approver23__c=userId2;
        requestRecord3.Approver24__c=userId2;
        requestRecord3.Approver25__c=userId2;
        update requestRecord3;
        
        
        
        IFv2_Request__c requestRecord5 = new IFv2_Request__c();
        requestRecord5.Status__c = 'Submitted';
        requestRecord5.Workflow__c = 'Overtime Request';
        requestRecord5.Account__c = testAccount.Id;
        requestRecord5.RequestExtension1__c=objExt1.id;
        requestRecord5.RequestExtension3__c=objExt3.id;
        requestRecord5.RequestExtension2__c=objExt2.id;
        requestRecord5.Approver1__c=userId1;
        requestRecord5.Approver2__c=userId1;
        requestRecord5.Approver3__c=userId1;
        insert requestRecord5;
        
        IFv2_Request__c requestRecord6 = new IFv2_Request__c();
        requestRecord6.Status__c = 'Submitted';
        requestRecord6.Workflow__c = 'Employee Suggestion Scheme US MX';
        requestRecord6.Account__c = testAccount.Id;
        requestRecord6.RequestExtension1__c=objExt1.id;
        requestRecord6.RequestExtension3__c=objExt3.id;
        requestRecord6.RequestExtension2__c=objExt2.id;
        requestRecord6.Approver1__c=userId1;
        requestRecord6.Approver2__c=userId1;
        requestRecord6.Approver3__c=userId1;
        insert requestRecord6;
        
        requestRecord5.Approver2__c=userId2;
        requestRecord5.Approver3__c=userId2;
        requestRecord5.Approver4__c=userId2;
        update requestRecord5;
        
        requestRecord6.Approver2__c=userId2;
        requestRecord6.Approver3__c=userId2;
        requestRecord6.Approver4__c=userId2;
        update requestRecord6;
        
        SET<Id> outOfOfficeUserIds = new SET<Id>(); 
        LIST<Id> backToOfficeuserIds = new LIST<Id>();
        String outofofficelogsrecordtypeid = Schema.SObjectType.IFv2_AdminOnly__c.getRecordTypeInfosByName().get('OutOfOfficeLogs').getRecordTypeId();
        String   query ='SELECT WorkflowName__c,User__c,createdbyid,Active__c'+
            ' FROM IFv2_AdminOnly__c a WHERE  recordtypeid=:outofofficelogsrecordtypeid  '+ 
            'AND createdbyid not in :outOfOfficeUserIds AND createdbyid not in :backToOfficeuserIds '+
            'AND WorkflowName__c!=Null AND User__c!=Null and (Active__c=true) limit 2';
        
        List<IFv2_AdminOnly__c> adminonlyRecords=Database.query(query);
        if(!adminonlyRecords.isEmpty()) {
            String workflow;
            MAP<String,String> delegatedIdworkflownameMap = new MAP<String,String>();
            
            //Iterating and collecting the created by id and delegated id and allso workflow
            for(IFv2_AdminOnly__c admin : adminonlyRecords) {
                //Collecting out of office userids
                if(admin.Active__c) {
                    outOfOfficeUserIds.add(admin.CreatedById);
                    delegatedIdworkflownameMap.put(admin.WorkflowName__c, admin.User__c);
                } else {
                    //collecting back to office user ids
                    backToOfficeuserIds.add(admin.CreatedById);
                    workflow = admin.WorkflowName__c ;
                }
            }
            //Invoking Out of office
            if(!outOfOfficeUserIds.isEmpty()) {
                IFv2_TriggerHandler.TransferApproverToDelegatedUserv1(outOfOfficeUserIds, delegatedIdworkflownameMap);
            }
        }
        test.stopTest();
        
    }
    
    public static testMethod void notifySubmittedTest()
    {
        test.startTest();
        
        IFv2_Request__c req = new IFv2_Request__c();
        req.Status__c = 'Draft';
        req.Workflow__c = 'Approval Process for Special Freights';
        insert req;
        
        req.Status__c = 'Approved';
        update req;
        
        test.stopTest();
    }
    
    public static testMethod void cancelRequestTest()
    {
        
        User objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        
        insert objUser;
        
        System.runAs(objUser) {
        Account testAccount = new Account();
        testAccount.name  = 'test';
        insert testAccount;
        
        IFv2_Workflow__c objWF = new IFv2_Workflow__c();
        objWF.Name = 'eSignature';
        objWF.Workflow__c = 'eSignature';
        objWF.ReminderAfterDays__c = 0;
        objWF.SubsequentReminderAfter__c = 0;
        list<IFv2_Workflow__c> lstWF = new list<IFv2_Workflow__c>();
        lstWF.add(objWF);
        insert lstWF;
        }
        test.starttest();
        System.runAs(new User(Id = Userinfo.getUserId())) {
        IFv2_Request__c req = new IFv2_Request__c();
        req.Status__c = 'Draft';
        req.Workflow__c = 'ICO Workflow - 6';
        req.CompanyCode__c = '71F0';
        req.InvoiceItemAmount__c = '50000';
        req.Approver1__c = objUser.Id;
        insert req;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(req.Id); 
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('IFv2_ICOWorkflow6');
        req1.setSkipEntryCriteria(false);
        Approval.ProcessResult result = Approval.process(req1);
        system.assertEquals(true,result.isSuccess());
        
        req.Status__c = 'Cancelled';
        update req;
        }
        test.stopTest();
    }
    
    public static testMethod void recordShareForDelegatedApproverTest2()
    {
        test.startTest();
        LIST<IFv2_Request__c> lstRequests = new LIST<IFv2_Request__c>();
        lstRequests = IFv2_testDataUtility.createRequest();
        lstRequests[0].Workflow__c = 'eSignature';
        lstRequests[0].Status__c = 'Submitted';
        insert lstRequests[0];
        
        SET<Id> delegateUserIdSET=new SET<Id>();
        delegateUserIdSET.add(Userinfo.getUserId());
        LIST<IFv2_Request__c> requestList=new List<IFv2_Request__c>();
        
        Account testAccount = new Account();
        testAccount.Name = 'Account for Contact';
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Request Items').getRecordTypeId();
		testAccount.IFv2_Request__c = lstRequests[0].Id;
            
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        objExt.TotalOriginalValue__c = 0.00;
        insert objExt;
        
        insert testAccount;
        
        IFv2_Request__c r = lstRequests[0];
        r.Account__c = testAccount.Id;
        r.RequestExtension1__c=objExt.id;
        update r;
        requestList.add(r);
        
        String jsonRequest=JSON.serialize(r);
        System.debug('jsonRequest>'+jsonRequest);
        IFv2_TriggerHandler.recordShareForDelegatedApprover(delegateUserIdSET,jsonRequest);
        
        test.stopTest();
    }
    
    public static testmethod void extensionSharingTestAPAC() {
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='apacTest',
            Alias = 'apactest',
            Email = 'apactest@test.com',
            Username = 'apactest@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
                
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        System.RunAs(lstUser[0])
        {
            objAcc = IFv2_testDataUtility.createAccount();
            insert objAcc;
            
            objCon = IFv2_testDataUtility.createContact(objAcc);
            insert objCon;
            objExt.TotalOriginalValue__c = 0.00;
            insert objExt;
            IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
            insert objExt2;
            IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
            insert objExt3;
            List<IFv2_Request__c> listRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
            listRequest[0].Status__c = 'Draft' ;
            listRequest[0].Workflow__c = 'Employee Suggestion Scheme'; 
            listRequest[0].RequestExtension1__c = objExt.id;
            listRequest[0].Account__c = objAcc.Id;
            listRequest[0].InformWhenApproved__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
            listRequest[0].Approver1__c = UserInfo.getUserId();
            listRequest[0].Approver2__c = UserInfo.getUserId();
            listRequest[0].Approver3__c = UserInfo.getUserId();
            listRequest[0].Approver4__c = UserInfo.getUserId();
            listRequest[0].Approver5__c = UserInfo.getUserId();
            listRequest[0].Approver6__c = UserInfo.getUserId();
            insert listRequest ;
            
            map<id,id> mapIds = new map<id,id>();
            mapIds.put(listRequest[0].Id,lstUser[0].Id);
            map<id,id> mapIds2 = new map<id,id>();
            mapIds2.put(listRequest[0].Id,user.Id);
            IFv2_TriggerHandler.CreateExtensionShareRecords(listRequest,mapIds,mapIds2);
        }
        
    }
    
    public static testmethod void extensionSharingTestEMEA() {
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='emeaTest',
            Alias = 'emeatest',
            Email = 'emeatest@test.com',
            Username = 'emestest@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
        
        
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        System.RunAs(lstUser[0])
        {
            objAcc = IFv2_testDataUtility.createAccount();
            insert objAcc;
            
            objCon = IFv2_testDataUtility.createContact(objAcc);
            insert objCon;
            objExt.TotalOriginalValue__c = 0.00;
            insert objExt;
            IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
            insert objExt2;
            IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
            insert objExt3;
            List<IFv2_Request__c> listRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
            listRequest[0].Status__c = 'Draft' ;
            listRequest[0].Workflow__c = 'Overtime Request Germany'; 
            listRequest[0].RequestExtension2__c = objExt2.id;
            listRequest[0].Account__c = objAcc.Id;
            listRequest[0].InformWhenApproved__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
            listRequest[0].Approver1__c = UserInfo.getUserId();
            listRequest[0].Approver2__c = UserInfo.getUserId();
            listRequest[0].Approver3__c = UserInfo.getUserId();
            listRequest[0].Approver4__c = UserInfo.getUserId();
            listRequest[0].Approver5__c = UserInfo.getUserId();
            listRequest[0].Approver6__c = UserInfo.getUserId();
            insert listRequest ;
            
            map<id,id> mapIds = new map<id,id>();
            mapIds.put(listRequest[0].Id,lstUser[0].Id);
            map<id,id> mapIds2 = new map<id,id>();
            mapIds2.put(listRequest[0].Id,user.Id);
            IFv2_TriggerHandler.CreateExtensionShareRecords(listRequest,mapIds,mapIds2);
        }
        
    }
    
    public static testmethod void extensionSharingTestNALA() {
        objUser = IFv2_testDataUtility.createUser();
        objUser.Country = 'Germany';
        list<user> lstUser = new list<user>(); 
        lstUser.add(objUser);
        insert lstUser;
        lstUser[0].Country = 'china';
        update lstUser[0];
        
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'IFv2_Extension1'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = lstUser[0].Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        user user=New User(
            LastName = 'LIVESTONE',
            FirstName='NALATest',
            Alias = 'Nalatest',
            Email = 'nalatesting@test.com',
            Username = 'nalatesting@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert user;
        
        IFv2_RequestExtension1__c objExt = new IFv2_RequestExtension1__c();
        System.RunAs(lstUser[0])
        {
            objAcc = IFv2_testDataUtility.createAccount();
            insert objAcc;
            
            objCon = IFv2_testDataUtility.createContact(objAcc);
            insert objCon;
            objExt.TotalOriginalValue__c = 0.00;
            insert objExt;
            IFv2_RequestExtension2__c objExt2 = new IFv2_RequestExtension2__c();
            insert objExt2;
            IFv2_RequestExtension3__c objExt3 = new IFv2_RequestExtension3__c();
            insert objExt3;
            List<IFv2_Request__c> listRequest = IFv2_testDataUtility.createRequest();  //inserting Request  
            listRequest[0].Status__c = 'Draft' ;
            listRequest[0].Workflow__c = 'NA Journal Entry Application'; 
            listRequest[0].RequestExtension3__c = objExt3.id;
            listRequest[0].Account__c = objAcc.Id;
            listRequest[0].InformWhenApproved__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved2__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved3__c = UserInfo.getUserId();
            listRequest[0].InformWhenApproved4__c = UserInfo.getUserId();
            listRequest[0].Approver1__c = UserInfo.getUserId();
            listRequest[0].Approver2__c = UserInfo.getUserId();
            listRequest[0].Approver3__c = UserInfo.getUserId();
            listRequest[0].Approver4__c = UserInfo.getUserId();
            listRequest[0].Approver5__c = UserInfo.getUserId();
            listRequest[0].Approver6__c = UserInfo.getUserId();
            insert listRequest ;
            
            map<id,id> mapIds = new map<id,id>();
            mapIds.put(listRequest[0].Id,lstUser[0].Id);
            map<id,id> mapIds2 = new map<id,id>();
            mapIds2.put(listRequest[0].Id,user.Id);
            IFv2_TriggerHandler.CreateExtensionShareRecords(listRequest,mapIds,mapIds2);
        }
        
    }
    
    public static testMethod void checkApproverLevelTest1()
    {
        List<User> lstUser = new List<user>(); 
        
        User objUser1 = IFv2_testDataUtility.createUser();
        objUser1.Country = 'Germany';
        
        lstUser.add(objUser1);
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User objUser2 = new User(
            LastName = 'Approver',
            FirstName='User1',
            Alias = 'au',
            Email = 'approveruser1@test.com',
            Username = 'approveruser1@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser2);
        
        User objUser3 = new User(
            LastName = 'Approver',
            FirstName='User2',
            Alias = 'au2',
            Email = 'approveruser2@test.com',
            Username = 'approveruser2@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser3);
        
        insert lstUser;
        System.runAs(new User(Id = Userinfo.getUserId())) {
        List<Approver_Level_Table__c> lstAppLevel = new List<Approver_Level_Table__c>();
        Approver_Level_Table__c apprLevel1 = new Approver_Level_Table__c();
        apprLevel1.Name = 'Map1';
        apprLevel1.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel1.Higher_Limit__c = '500';
        apprLevel1.Approver_Level__c = 'Level 1';
        apprLevel1.Approver_Id__c = lstUser[0].Id;
        lstAppLevel.add(apprLevel1);
        
        Approver_Level_Table__c apprLevel2 = new Approver_Level_Table__c();
        apprLevel2.Name = 'Map2';
        apprLevel2.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel2.Higher_Limit__c = '20000';
        apprLevel2.Approver_Level__c = 'Level 2';
        apprLevel2.Approver_Id__c = lstUser[1].Id;
        lstAppLevel.add(apprLevel2);
        
        Approver_Level_Table__c apprLevel3 = new Approver_Level_Table__c();
        apprLevel3.Name = 'Map3';
        apprLevel3.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel3.Higher_Limit__c = '100000';
        apprLevel3.Approver_Level__c = 'Level 3';
        apprLevel3.Approver_Id__c = lstUser[2].Id;
        lstAppLevel.add(apprLevel3);
        insert lstAppLevel;
        }
        test.startTest();
        System.runAs(lstUser[0]) {
            Account testAccount = new Account();
            testAccount.name  = 'test';
            testAccount.IFv2_InvoicingPartyvendornumber__c = '0097361152';
            testAccount.IFv2_ItemText__c = 'FF 50000';
            insert testAccount;
            
            IFv2_Request__c req = new IFv2_Request__c();
            req.Status__c = 'Draft';
            req.Workflow__c = 'ICO Workflow - 6';
            req.CompanyCode__c = '71F0';
            req.InvoiceItemAmount__c = '50000';
            req.Approver1__c = lstUser[0].Id;
            req.Approver2__c = lstUser[1].Id;
            req.Account__c = testAccount.Id;
            insert req;
            
            try{
                req.Approver1__c = userInfo.getUserId();
                update req;
            }
            catch(Exception e){
                System.debug('Validation Error');
            }
        }        
        test.stopTest();
    }
    
     public static testMethod void checkApproverLevelTest2()
    {
        List<User> lstUser = new List<user>(); 
        
        User objUser1 = IFv2_testDataUtility.createUser();
        objUser1.Country = 'Germany';
        
        lstUser.add(objUser1);
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User objUser2 = new User(
            LastName = 'Approver',
            FirstName='User1',
            Alias = 'au',
            Email = 'approveruser1@test.com',
            Username = 'approveruser1@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser2);
        
        User objUser3 = new User(
            LastName = 'Approver',
            FirstName='User2',
            Alias = 'au2',
            Email = 'approveruser2@test.com',
            Username = 'approveruser2@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser3);
        
        insert lstUser;
        System.runAs(new User(Id = Userinfo.getUserId())) {
        List<Approver_Level_Table__c> lstAppLevel = new List<Approver_Level_Table__c>();
        Approver_Level_Table__c apprLevel1 = new Approver_Level_Table__c();
        apprLevel1.Name = 'Map1';
        apprLevel1.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel1.Higher_Limit__c = '500';
        apprLevel1.Approver_Level__c = 'Level 1';
        apprLevel1.Approver_Id__c = lstUser[0].Id;
        lstAppLevel.add(apprLevel1);
        
        Approver_Level_Table__c apprLevel2 = new Approver_Level_Table__c();
        apprLevel2.Name = 'Map2';
        apprLevel2.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel2.Higher_Limit__c = '20000';
        apprLevel2.Approver_Level__c = 'Level 2';
        apprLevel2.Approver_Id__c = lstUser[1].Id;
        lstAppLevel.add(apprLevel2);
        
        Approver_Level_Table__c apprLevel3 = new Approver_Level_Table__c();
        apprLevel3.Name = 'Map3';
        apprLevel3.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel3.Higher_Limit__c = '100000';
        apprLevel3.Approver_Level__c = 'Level 3';
        apprLevel3.Approver_Id__c = lstUser[2].Id;
        lstAppLevel.add(apprLevel3);
        insert lstAppLevel;
        }
        test.startTest();
        System.runAs(lstUser[0]) {
        	Account testAccount = new Account();
        	testAccount.name  = 'test';
        	testAccount.IFv2_InvoicingPartyvendornumber__c = '0097361152';
        	testAccount.IFv2_ItemText__c = 'FF 50000';
        	insert testAccount;
            
            IFv2_Request__c req = new IFv2_Request__c();
            req.Status__c = 'Draft';
            req.Workflow__c = 'ICO Workflow - 6';
            req.CompanyCode__c = '71F0';
            req.InvoiceItemAmount__c = '50000';
            req.Approver1__c = lstUser[0].Id;
            req.Approver2__c = lstUser[2].Id;
            req.Approver3__c = lstUser[1].Id;
            req.Account__c = testAccount.Id;
            
            insert req;
            try{
                req.Approver1__c = userInfo.getUserId();
                update req;
            }
            catch(Exception e){
                System.debug('Validation Error');
            }
        }
        test.stopTest();
    }
    
    public static testMethod void checkApproverLevelTest3()
    {
        List<User> lstUser = new List<user>(); 
        
        User objUser1 = IFv2_testDataUtility.createUser();
        objUser1.Country = 'Germany';
        
        lstUser.add(objUser1);
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User objUser2 = new User(
            LastName = 'Approver',
            FirstName='User1',
            Alias = 'au',
            Email = 'approveruser3@test.com',
            Username = 'approveruser3@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser2);
        
        User objUser3 = new User(
            LastName = 'Approver',
            FirstName='User2',
            Alias = 'au2',
            Email = 'approveruser4@test.com',
            Username = 'approveruser4@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser3);
        
        insert lstUser;
        System.runAs(new User(Id = Userinfo.getUserId())) {
        List<Approver_Level_Table__c> lstAppLevel = new List<Approver_Level_Table__c>();
        Approver_Level_Table__c apprLevel1 = new Approver_Level_Table__c();
        apprLevel1.Name = 'Map1';
        apprLevel1.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel1.Higher_Limit__c = '500';
        apprLevel1.Approver_Level__c = 'Level 1';
        apprLevel1.Approver_Id__c = lstUser[0].Id;
        lstAppLevel.add(apprLevel1);
        
        Approver_Level_Table__c apprLevel2 = new Approver_Level_Table__c();
        apprLevel2.Name = 'Map2';
        apprLevel2.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel2.Higher_Limit__c = '20000';
        apprLevel2.Approver_Level__c = 'Level 2';
        apprLevel2.Approver_Id__c = lstUser[1].Id;
        lstAppLevel.add(apprLevel2);
        
        Approver_Level_Table__c apprLevel3 = new Approver_Level_Table__c();
        apprLevel3.Name = 'Map3';
        apprLevel3.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel3.Higher_Limit__c = '100000';
        apprLevel3.Approver_Level__c = 'Level 3';
        apprLevel3.Approver_Id__c = lstUser[2].Id;
        lstAppLevel.add(apprLevel3);
        insert lstAppLevel;
        }
        test.startTest();
        System.runAs(lstUser[0]) {
            Account testAccount = new Account();
        	testAccount.name  = 'test';
        	testAccount.IFv2_InvoicingPartyvendornumber__c = '0097361152';
        	testAccount.IFv2_ItemText__c = 'FF 25000';
        	insert testAccount;
            
            IFv2_Request__c req = new IFv2_Request__c();
            req.Status__c = 'Draft';
            req.Workflow__c = 'ICO Workflow - 6';
            req.CompanyCode__c = '71F0';
            req.InvoiceItemAmount__c = '25000';
            req.Approver1__c = lstUser[0].Id;
            req.Approver2__c = lstUser[0].Id;
            req.Approver3__c = lstUser[1].Id;
            req.Account__c = testAccount.Id;
            insert req;
            try{
                req.Approver1__c = userInfo.getUserId();
                update req;
            }
            catch(Exception e){
                System.debug('Validation Error');
            }
        }
        test.stopTest();
    }
    
    /*public static testMethod void checkApproverLevelICTest1()
    {
        List<User> lstUser = new List<user>(); 
        
        User objUser1 = IFv2_testDataUtility.createUser();
        objUser1.Country = 'Germany';
        
        lstUser.add(objUser1);
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User objUser2 = new User(
            LastName = 'Approver',
            FirstName='User1',
            Alias = 'au',
            Email = 'approveruser1@test.com',
            Username = 'approveruser1@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser2);
        
        User objUser3 = new User(
            LastName = 'Approver',
            FirstName='User2',
            Alias = 'au2',
            Email = 'approveruser2@test.com',
            Username = 'approveruser2@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser3);
        
        insert lstUser;
        System.debug('lstUser::'+lstUser);
        System.debug('lstUser0::'+lstUser[0]);
        System.debug('lstUser1::'+lstUser[1]);
        System.debug('lstUser2::'+lstUser[2]);
        System.runAs(new User(Id = Userinfo.getUserId())) {
        List<Approver_Level_Table__c> lstAppLevel = new List<Approver_Level_Table__c>();
        Approver_Level_Table__c apprLevel1 = new Approver_Level_Table__c();
        apprLevel1.Name = 'Map1';
        apprLevel1.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel1.Higher_Limit__c = '500';
        apprLevel1.Approver_Level__c = 'Level 1';
        apprLevel1.Approver_Id__c = lstUser[0].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel1);
        
        Approver_Level_Table__c apprLevel2 = new Approver_Level_Table__c();
        apprLevel2.Name = 'Map2';
        apprLevel2.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel2.Higher_Limit__c = '20000';
        apprLevel2.Approver_Level__c = 'Level 2';
        apprLevel2.Approver_Id__c = lstUser[1].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel2);
        
        Approver_Level_Table__c apprLevel3 = new Approver_Level_Table__c();
        apprLevel3.Name = 'Map3';
        apprLevel3.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel3.Higher_Limit__c = '100000';
        apprLevel3.Approver_Level__c = 'Level 3';
        apprLevel3.Approver_Id__c = lstUser[2].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel3);
        insert lstAppLevel;
        }
        test.startTest();
        System.runAs(lstUser[0]) {
        Account testAccount = new Account();
        testAccount.name  = 'test';
        testAccount.IFv2_InvoicingPartyvendornumber__c = '0097361152';
        insert testAccount;
            
        IFv2_Request__c req = new IFv2_Request__c();
        req.Status__c = 'Draft';
        req.Workflow__c = 'ICO Workflow - 6';
        req.CompanyCode__c = '71F0';
        req.InvoiceItemAmount__c = '50000';
        req.Approver1__c = lstUser[0].Id;
        req.Approver2__c = lstUser[1].Id;
        req.Account__c = testAccount.Id;
        insert req;
        
        req.Approver1__c = userInfo.getUserId();
        update req;
        }        
        test.stopTest();
    }*/
    
     public static testMethod void checkApproverLevelICTest2()
    {
        List<User> lstUser = new List<user>(); 
        
        User objUser1 = IFv2_testDataUtility.createUser();
        objUser1.Country = 'Germany';
        
        lstUser.add(objUser1);
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User objUser2 = new User(
            LastName = 'Approver',
            FirstName='User1',
            Alias = 'au',
            Email = 'approveruser1@test.com',
            Username = 'approveruser1@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser2);
        
        User objUser3 = new User(
            LastName = 'Approver',
            FirstName='User2',
            Alias = 'au2',
            Email = 'approveruser2@test.com',
            Username = 'approveruser2@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser3);
        
        insert lstUser;
        System.runAs(new User(Id = Userinfo.getUserId())) {
        List<Approver_Level_Table__c> lstAppLevel = new List<Approver_Level_Table__c>();
        Approver_Level_Table__c apprLevel1 = new Approver_Level_Table__c();
        apprLevel1.Name = 'Map1';
        apprLevel1.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel1.Higher_Limit__c = '500';
        apprLevel1.Approver_Level__c = 'Level 1';
        apprLevel1.Approver_Id__c = lstUser[0].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel1);
        
        Approver_Level_Table__c apprLevel2 = new Approver_Level_Table__c();
        apprLevel2.Name = 'Map2';
        apprLevel2.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel2.Higher_Limit__c = '20000';
        apprLevel2.Approver_Level__c = 'Level 2';
        apprLevel2.Approver_Id__c = lstUser[1].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel2);
        
        Approver_Level_Table__c apprLevel3 = new Approver_Level_Table__c();
        apprLevel3.Name = 'Map3';
        apprLevel3.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel3.Higher_Limit__c = '100000';
        apprLevel3.Approver_Level__c = 'Level 3';
        apprLevel3.Approver_Id__c = lstUser[2].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel3);
        insert lstAppLevel;
        }
        test.startTest();
        System.runAs(lstUser[0]) {
            Account testAccount = new Account();
            testAccount.name  = 'test';
            testAccount.IFv2_InvoicingPartyvendornumber__c = '0097361152';
        	testAccount.IFv2_ItemText__c = 'FF 50000';
            insert testAccount;
            
            IFv2_Request__c req = new IFv2_Request__c();
            req.Status__c = 'Draft';
            req.Workflow__c = 'ICO Workflow - 6';
            req.CompanyCode__c = '71F0';
            req.InvoiceItemAmount__c = '50000';
            req.Approver1__c = lstUser[0].Id;
            req.Approver2__c = lstUser[2].Id;
            req.Approver3__c = lstUser[1].Id;
            req.Account__c = testAccount.Id;
            insert req;
            try{
                req.Approver1__c = userInfo.getUserId();
                update req;
            }
            catch(Exception e){
                System.debug('Validation Error');
            }
        }
        test.stopTest();
    }

    public static testMethod void checkApproverLevelICTest3()
    {
        List<User> lstUser = new List<user>(); 
        
        User objUser1 = IFv2_testDataUtility.createUser();
        objUser1.Country = 'Germany';
        
        lstUser.add(objUser1);
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User objUser2 = new User(
            LastName = 'Approver',
            FirstName='User1',
            Alias = 'au',
            Email = 'approveruser3@test.com',
            Username = 'approveruser3@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser2);
        
        User objUser3 = new User(
            LastName = 'Approver',
            FirstName='User2',
            Alias = 'au2',
            Email = 'approveruser4@test.com',
            Username = 'approveruser4@test.com',
            ProfileId = profileId.id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        lstUser.add(objUser3);
        
        insert lstUser;
        System.runAs(new User(Id = Userinfo.getUserId())) {
        List<Approver_Level_Table__c> lstAppLevel = new List<Approver_Level_Table__c>();
        Approver_Level_Table__c apprLevel1 = new Approver_Level_Table__c();
        apprLevel1.Name = 'Map1';
        apprLevel1.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel1.Higher_Limit__c = '500';
        apprLevel1.Approver_Level__c = 'Level 1';
        apprLevel1.Approver_Id__c = lstUser[0].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel1);
        
        Approver_Level_Table__c apprLevel2 = new Approver_Level_Table__c();
        apprLevel2.Name = 'Map2';
        apprLevel2.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel2.Higher_Limit__c = '20000';
        apprLevel2.Approver_Level__c = 'Level 2';
        apprLevel2.Approver_Id__c = lstUser[1].Id;
        apprLevel1.Invoicing_Party_Number__c = true;
        lstAppLevel.add(apprLevel2);
        
        Approver_Level_Table__c apprLevel3 = new Approver_Level_Table__c();
        apprLevel3.Name = 'Map3';
        apprLevel3.Workflow_Name__c = 'ICO Workflow - 6';
        apprLevel3.Higher_Limit__c = '100000';
        apprLevel3.Approver_Level__c = 'Level 3';
        apprLevel3.Approver_Id__c = lstUser[2].Id;
        lstAppLevel.add(apprLevel3);
        insert lstAppLevel;
        }
        test.startTest();
        System.runAs(lstUser[0]) {
            Account testAccount = new Account();
            testAccount.name  = 'test';
            testAccount.IFv2_InvoicingPartyvendornumber__c = '0097361152';
        	testAccount.IFv2_ItemText__c = 'FF 25000';
            insert testAccount;
            
            IFv2_Request__c req = new IFv2_Request__c();
            req.Status__c = 'Draft';
            req.Workflow__c = 'ICO Workflow - 6';
            req.CompanyCode__c = '71F0';
            req.InvoiceItemAmount__c = '25000';
            req.Approver1__c = lstUser[0].Id;
            req.Approver2__c = lstUser[0].Id;
            req.Approver3__c = lstUser[1].Id;
            req.Account__c = testAccount.Id;
            insert req;
            try{
                req.Approver1__c = userInfo.getUserId();
                update req;
            }
            catch(Exception e){
                System.debug('Validation Error');
            }
        }
        test.stopTest();
    }
}