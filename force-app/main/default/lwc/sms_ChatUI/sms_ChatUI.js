import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getChatCount from '@salesforce/apex/HM_smsChatController.getChat_Count';
import getTodayChatCount from '@salesforce/apex/HM_smsChatController.getTodayChat_Count';
import getCaseDetail from '@salesforce/apex/HM_smsChatController.getCaseDetails';
import getChatLog from '@salesforce/apex/HM_smsChatController.getChatLogs';
import sendMessageToHM from '@salesforce/apex/HM_SendMessageToHM.sendMessage';
import resendWelcomeMsg from '@salesforce/apex/HM_ResendWelcomeMessage.HM_resendwelcomeMessage';
import getTextLanguages from '@salesforce/apex/HM_smsChatController.getLanguageValues';
import updateTextLanguage from '@salesforce/apex/HM_smsChatController.updateTextLanguageOnCase';
import updateChatLog from '@salesforce/apex/HM_smsChatController.updateUnreadMessageCount';
import createCaseInHM from '@salesforce/apex/HM_smsChatController.updateCreateCaseInHM';
import HiMarley_Logo from '@salesforce/resourceUrl/HM_Logo';

export default class Sms_ChatUI extends LightningElement {

    @api recordId;
    @track progress = 2000;
    @track getChats = [];
    @track chatData = [];
    @track caseDetail = [];
    @track error;
    @track isShowModal = false;
    @track isShowOptOutModel = false;
    @track options;
    textLanguage = '';
    wiredChatLogs;
    wiredCaseDetails;
    chatCount = '';
    inputMessage = '';
    caseId = '';
    contactFirstName = '';
    contactName = '';
    optInDate = '';
    optInTime = '';
    showOptInFlag = false;
    showErrorOptedIn = false;
    showErrorOptedOut = false;
    sCaseClosed = '';
    disableSend = false;
    backgroundColor = 'background-color:white';
    showchatLogs = false;
    showErrorNoChats = false;
    showErrorNoHMCase = false;
    showTodayChats = false;
    showOptInDate = true;
    disableStartConversation = false;
    hmlogo = HiMarley_Logo;
    //chat_Limit = 10;
    //offsetNumber = 1;

    connectedCallback() {

        this.caseId = this.recordId;
        console.log('this.caseId ==> ' + this.caseId);

        //refresh chat window after every 5 seconds for 5 minutes
        var sfdcBaseUrl = window.location.toString();;
        if (sfdcBaseUrl.includes(this.recordId)) {
            this._interval = setInterval(() => {
                this.progress = this.progress + 3000;
                if (this.progress === 300000) {
                    clearInterval(this._interval);
                }
               this.refereshChats();  
            }, this.progress);
           
        }
       
        //Display Text Language Value on Chat
        getTextLanguages({ objApiName: 'Case', fieldName: 'HM_Text_Language__c' })
            .then(data => {
                //console.log('data' + data);
                this.options = data;
            })
            .catch(error => {
                console.log('getTextLanguages error : ' + error);
            });
    }

    //Scroll Bar added at the bottom
    showScroll() {
        const scrollArea = this.template.querySelector('[data-scroll-area]');
        console.log('scrollArea' + scrollArea);
        if (scrollArea == null) {
            return;
        }
        scrollArea.scrollTop = scrollArea.scrollHeight;
    }

    //Show total chat count related to the case
    async showChatCount() {
        //console.log('showChatCount');
        return new Promise(async (resolve, reject) => {
            var result = await getChatCount({ sCaseId: this.caseId });
            this.chatCount = result;
            this.showNoChats();
            resolve(result);
        });
    }

    //Show total chat count related to the case
    async showTodayChatCount() {
        return new Promise(async (resolve, reject) => {
            var result = await getTodayChatCount({ sCaseId: this.caseId });
            this.showTodaysChat(result);  
            console.log('Chats for Today ==> ' + result);      
            resolve(result);
        });
    }
    
    //Show Chats Window for Today
    showTodaysChat(result) {
        console.log('showTodaysChat : ' + result);
        if (result == 0 || result == undefined) {
            this.showTodayChats = false;
            console.log('this.showTodayChats : ' + this.showTodayChats);
        }
        else {
            this.showTodayChats = true;
            console.log('this.showTodayChats : ' + this.showTodayChats);
        }
    }


    //Get Case Details 
    @wire(getCaseDetail, { sCaseId: '$recordId' })
    wiredCase( result ) {
        this.wiredCaseDetails = result;
        if (result.data) {
            console.log('case method');
            this.caseDetail = result.data;
            this.getCaseData();
        } else if (result.error) {
            console.log('Something went wrong:', error);
        }
    }

    //Get All Chat Messages related to the case 
    @wire(getChatLog, { sCaseId: '$recordId' })
    async wiredChat(result) {
        //console.log('wiredChat');
        await this.showChatCount();
        await this.showTodayChatCount();
        this.wiredChatLogs = result;
        if (result.data) {
            this.getChats = result.data;
            console.log('ChatData :' + this.getChats.length);
            this.getChatLogsOnLoad();
            this.showScroll();
        }
        else if (result.error) {
            console.log('Something went wrong:', error);
        }
    }

    /*
    //Code for Lazy Loading
    loadMoreChat() {
        console.log('IN the load Data');
        this.offsetNumber = this.offsetNumber + 1;

        getChatLog({ sCaseId: this.caseId, chatLimit: this.chat_Limit, offset: this.offsetNumber })
            .then((data) => {
                //console.log('Load data');
                if (this.getChats.length != 0) {
                    this.getChats = this.getChats.concat(data);
                    this.getChatLogsOnLoad();
                } else {
                    this.getChats = data;
                    this.getChatLogsOnLoad();
                }
            });

           // this.showScroll(); 
    }
    */

    //Update Text Language value Onchange
    selectionChangeHandler(event) {

        console.log('Value : ' + event.target.value);
        var value = event.target.value;

        //Update Text Language Value on Case
        updateTextLanguage({ sCaseId: this.caseId, textLanguage: value });
        location.reload();
    }


    //refresh chat window every 5 seconds
    refereshChats() {
        console.log('refreshChats');

       //Mark Unread Chat Logs as Read Messages 
        this.markChatLogAsRead();

        return refreshApex(this.wiredChatLogs)
            .then(() => {
                console.log('refresh apex complete!');
                return refreshApex(this.wiredCaseDetails)
                    .then(() => {
                        //console.log('refresh!');
                    }).catch(() => {
                        //console.log('Error!');
                    });
            }).catch(() => {
                console.log('Error in Refresh Apex!');
            });          
    }

    //Mark Unread Chat Logs as Read Messages 
    markChatLogAsRead() {

        updateChatLog({ sCaseId: this.caseId })
            .then(data => {
                //console.log('updateChatLog success' + data);
            })
            .catch(error => {
                //console.log('updateChatLog error : ' + error);
            });
    }

    //show component 
    showNoChats() {
        console.log('showNoChats : ' + this.chatCount);
        if (this.showErrorNoHMCase != true) {
            if (this.chatCount == 0 || this.chatCount == undefined) {
                this.showErrorNoChats = true;
                this.showchatLogs = false;
                console.log('this.showErrorNoChats : ' + this.showErrorNoChats);
            }
            else {
                this.showchatLogs = true;
                this.showErrorNoChats = false;
                console.log('this.showchatLogs : ' + this.showchatLogs);
            }
        }
    }

    //Map Contact Details from Case Data
    getCaseData() {
        for (let i = 0; i < this.caseDetail.length; i++) {
            this.contactName = this.caseDetail[i].sContactName;
            this.contactFirstName = this.caseDetail[i].sContactFirstName;
            this.optInDate = this.caseDetail[i].sOptInDate;
            this.optInTime = this.caseDetail[i].sOptInTime;
            this.textLanguage = this.caseDetail[i].sTextLanguage;

            //show error - when the case is not created in Hi Marley
            if(this.caseDetail[i].sHMCaseId == null || this.caseDetail[i].sHMCaseId == ''){
                //Disable Start Conversation button if Contact is not Present on Case
                if(this.contactName == null || this.contactName == '' || this.contactName == undefined) {
                    this.disableStartConversation = true;
                }
                this.showErrorNoHMCase = true;
                this.showErrorNoChats = false;
                this.showchatLogs = false;
                this.disableSend = true;
                this.backgroundColor = 'background-color:#f3f2f2';
                this.showErrorOptedIn = false;
                this.showErrorOptedOut = false;
            }
            

            //show user Opted-In Error
            if (this.showErrorNoHMCase != true) {
                if ((this.caseDetail[i].bIsOptedIn == false && this.caseDetail[i].sOptInStatus == 'REQUESTED') ||
                    (this.caseDetail[i].bIsOptedIn == false && this.caseDetail[i].sOptInStatus == '' ||
                        this.caseDetail[i].sOptInStatus == undefined)) {
                    this.showErrorOptedIn = true;
                    this.disableSend = true;
                    this.backgroundColor = 'background-color:#f3f2f2';
                }

                //Hide Opt-In Error if Contact is not present
                if (this.contactName == null || this.contactName == '' || this.contactName == undefined){
                   this.showErrorOptedIn = false;
                }

                //show user Opted-Out Error
                if (this.caseDetail[i].bIsOptedIn == false && this.caseDetail[i].sOptInStatus == 'OPTED_OUT') {
                    this.IsOptedOut = 'OPTED_OUT';
                    this.showErrorOptedOut = true;
                    this.disableSend = true;
                    this.backgroundColor = 'background-color:#f3f2f2';
                }

                //show user Opted-In Flag
                if (this.caseDetail[i].bIsOptedIn == true && this.caseDetail[i].sOptInStatus == 'OPTED_IN') {
                    this.showOptInFlag = true;
                    //Show Opt-In Date & Time or Not
                    if (this.caseDetail[i].sOptInDate == null || this.caseDetail[i].sOptInDate == '' || this.caseDetail[i].sOptInDate == undefined ||
                        this.caseDetail[i].sOptInTime == null || this.caseDetail[i].sOptInTime == null || this.caseDetail[i].sOptInTime == null) {
                        this.showOptInDate = false;
                    }
                }
            }
            
            //Disable chat if the case is closed
            if (this.caseDetail[i].bIsClosed == true) {
                console.log('Case Closed');
                this.sCaseClosed = 'Closed';
                this.disableSend = true;
                this.backgroundColor = 'background-color:#f3f2f2';
            }

        }

    }

    //Display Existing Chats on UI
    getChatLogsOnLoad() {

        console.log('Chats::' + this.getChats.length);
    
        for (let i = 0; i < this.getChats.length; i++) {
          
            var messageData = this.getChats[i].sMessage;
            var authorName = this.getChats[i].sAuthorName;
            var createdDate = this.getChats[i].dtCreatedDate;
            var createdTime = this.getChats[i].dtCreatedTime;
            var messageId = this.getChats[i].sMessageId;
            var messageType = this.getChats[i].sMessageType;
            var authorInitials = this.getChats[i].sAuthorInitials;
            var source = this.getChats[i].sChannelSource;
            var createdDateTime = this.getChats[i].dtCreatedDtTime;
            var translatedMessage = this.getChats[i].sTranslatedMessage;
            var bIsUserOptedIn = this.getChats[i].bIsOptedIn;
            var bUserOptStatus = this.getChats[i].sOptStatus;
            var imagePublicUrl = this.getChats[i].sImagePublicUrl;

            console.log('source::' + source);
            console.log('Chats::' + messageData);


            // Get the current date/time in UTC
            let rightNow = new Date();

            // Adjust for the user's time zone
            rightNow.setMinutes(
                new Date().getMinutes() - new Date().getTimezoneOffset()
            );

            // Return the date in "YYYY-MM-DD" format
            let currentDate = rightNow.toISOString().slice(0, 10);

            console.log(createdDateTime);
            console.log(currentDate);

            //Create Inbound-Outbound Chat Messages
            if (this.chatData.includes(this.getChats[i].sChatLogId)) {
                //to avoid duplicate chat message creation
            }
            else {
                if(createdDateTime != currentDate) {
                    if (this.getChats[i].sChannelSource == 'marley' || this.getChats[i].sChannelSource == 'ai') {
                        this.handleOutboundMessage(messageData, authorName, createdDate, createdTime, messageId, authorInitials, source, translatedMessage);
                        this.chatData.push(this.getChats[i].sChatLogId);
                    }
                    else if (this.getChats[i].sChannelSource == 'mobile') {
                        this.handleInboundMessage(messageData, authorName, createdDate, createdTime, messageType, authorInitials, translatedMessage, imagePublicUrl);
                        this.chatData.push(this.getChats[i].sChatLogId);
                        
                    }
                }
                else {
                    if (this.getChats[i].sChannelSource == 'marley' || this.getChats[i].sChannelSource == 'ai') {
                        this.handleTodayOutboundMessage(messageData, authorName, createdDate, createdTime, messageId, authorInitials, source, translatedMessage);
                        this.chatData.push(this.getChats[i].sChatLogId);
                    }
                    else if (this.getChats[i].sChannelSource == 'mobile') {

                       console.log('bIsUserOptedIn' + bIsUserOptedIn);
                       console.log('bUserOptStatus' + bUserOptStatus);

                        this.handleTodayInboundMessage(messageData, authorName, createdDate, createdTime, messageType, authorInitials, translatedMessage, imagePublicUrl);
                        this.chatData.push(this.getChats[i].sChatLogId);                      

                        //show user Opted-Out Error
                        if (bIsUserOptedIn == false && bUserOptStatus == 'OPTED_OUT') {
                            this.IsOptedOut = 'OPTED_OUT';
                            this.showErrorOptedOut = true;
                            this.disableSend = true;
                            this.backgroundColor = 'background-color:#f3f2f2';
                        }
                         
                        //show user Opted-In Flag
                        if (bIsUserOptedIn == true && bUserOptStatus == 'OPTED_IN') {
                            this.showErrorOptedIn = false;
                            this.showOptInFlag = true;
                            this.showErrorOptedOut = false;
                            this.disableSend = false;
                            this.backgroundColor = 'white';
                        }                    

                        if (this.sCaseClosed == 'Closed') {
                            this.disableSend = true;
                            this.backgroundColor = 'background-color:#f3f2f2;';
                        }
                    }
                }
                
            }

        }
    }

    //Resend Welcome Message 
    resendWelcomeMessage(event) {
        console.log('resend welcome message');
        resendWelcomeMsg({ sCaseId: this.caseId })
            .then((result) => {
                console.log('result--->> ', result);
                if (result == 'Success') {
                    const event = new ShowToastEvent({
                        title: 'Welcome Message',
                        message: 'Welcome Message sent successfully!',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                } else {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Oops..Something went wrong!',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                }
            })
            .catch(error => {
                // to get error message in inspect logs
                console.log('error');
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Oops..Something went wrong!',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            });
    }

    //Get Input Message body
    getMessage(event) {
        //console.log('Input Message : ' + event.detail.value);
        this.inputMessage = event.detail.value;
    }

    //Check if the Text-area is blank
    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    //Send Message 
    sendMessage(event) {
        if (this.isInputValid()) {
            var message = this.inputMessage;
            //Pass Message and CaseId to Send Message to HM
            sendMessageToHM({ sMessage: message, sCaseId: this.caseId })
                .then((result) => {
                    console.log('result--->> ', result);
                    if (result == 'success') {
                        this.refereshChats();                       
                    }
                })
                .catch(error => {
                    // to get error message in inspect logs
                    console.log(error);
                });

            this.inputMessage = '';
        }
    }

    //Start Conversation - Create Case in Hi Marley
    createCaseInHM(event) {
        //Display Text Language Value on Chat
        createCaseInHM({ sCaseId: this.caseId })
            .then(data => {
                alert('SMS Conversation has been initiated. Do you want to refresh the page?');
                location.reload();
            })
            .catch(error => {
                console.log('createCaseInHM Error : ' + Error);
            });
    }

    //Pushing the received message to chat window (Inbound Message)
    handleInboundMessage(message, authorName, createdDate, createdTime, messageType, authorInitials, translatedMessage, imagePublicUrl) {

        //Attach Link Attribute
        var imageLink;
        if(messageType == 'image'){
          //imageLink = '<span> <a href=' + message + ' target="_blank">' + message + '</a></span>' ;
          imageLink = '<span> <a href=' + imagePublicUrl + ' target="_blank"> <img src="' + message + '" height="100px" width="100px"/></a></span>' ;
        }
        else{
           imageLink = '<span>' + message + '</span>';
        }

        var ul = this.template.querySelector('[data-id="chatList"]');
        var li = document.createElement("li")
        li.setAttribute("class", "slds-chat-listitem slds-chat-listitem_inbound");

        //Check if there is Translated Message
        if(translatedMessage != null && translatedMessage != undefined){
            
            li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +            
            '<div class="slds-chat-message__body">' +
            '<div class="slds-chat-message__text slds-chat-message__text_inbound" style="border:1px solid #c9c9c9;">' +
             imageLink +           
            '</div>' +
            '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
            '<p class="slds-m-left_x-small slds-m-top_xx-small"> <b> Translated Message </b> </p>' +
            '<p class="slds-m-left_x-small slds-m-top_xx-small">' + translatedMessage + '</p>' +
            '</span> </div>' +
            '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
            '</div>' +
            '</div>';

        }
        else{

            li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +            
            '<div class="slds-chat-message__body">' +
            '<div class="slds-chat-message__text slds-chat-message__text_inbound" style="border:1px solid #c9c9c9;">' +
             imageLink +           
            '</div>' +
            '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
            '</div>' +
            '</div>';
        }
       
        ul.appendChild(li);
    }

    //Pushing the sent message to chat window (Outbound Message)
    handleOutboundMessage(message, authorName, createdDate, createdTime, messageId, authorInitials, source, translatedMessage) {
        console.log('in handleOutboundMessage');
        var ul = this.template.querySelector('[data-id="chatList"]');
        var li = document.createElement("li");
        li.setAttribute("class", "slds-chat-listitem slds-chat-listitem_outbound");
        if (messageId != null) {
            if (source == 'ai') {
                //Check if there is Translated Message
                if (translatedMessage != null && translatedMessage != undefined) {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound" style="background-color:grey;">' +
                        '<span>' + message + '</span>' +
                        '</div>' +
                        '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small"> <b> Translated Message </b> </p>' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small">' + translatedMessage + '</p>' +
                        '</span> </div>' +
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }
                else {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound" style="background-color:grey;">' +
                        '<span>' + message + '</span>' +
                        '</div>' +
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }

            } else {
                //Check if there is Translated Message
                if (translatedMessage != null && translatedMessage != undefined) {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound">' +
                        '<span>' + message + '</span>' +
                        '</div>' +
                        '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small"> <b> Translated Message </b> </p>' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small">' + translatedMessage + '</p>' +
                        '</span> </div>' +
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }
                else {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound">' +
                        '<span>' + message + '</span>' +
                        '</div>' +
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }
            }
        }
        else {

            //Check if there is Translated Message
            if (translatedMessage != null && translatedMessage != undefined) {
                li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                    '<div class="slds-chat-message__body">' +
                    '<div class="slds-chat-message__text slds-chat-message__text_delivery-failure slds-m-right_x-small">' +
                    '<span class="slds-icon_container slds-icon-utility-error slds-chat-icon">' +
                    '<svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-icon-text-default" aria-hidden="true">' +
                    '<use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#warning"></use>' +
                    '</svg>' +
                    '<span class="slds-assistive-text">Warning</span>' +
                    '</span>' +
                    '<span>' + message + '</span>' +
                    '</div>' +
                    '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
                    '<p class="slds-m-left_x-small slds-m-top_xx-small"> <b> Translated Message </b> </p>' +
                    '<p class="slds-m-left_x-small slds-m-top_xx-small">' + translatedMessage + '</p>' +
                    '</span> </div>' +
                    '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                    '</div>' +
                    '</div>';
            }
            else {
                li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                    '<div class="slds-chat-message__body">' +
                    '<div class="slds-chat-message__text slds-chat-message__text_delivery-failure slds-m-right_x-small">' +
                    '<span class="slds-icon_container slds-icon-utility-error slds-chat-icon">' +
                    '<svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-icon-text-default" aria-hidden="true">' +
                    '<use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#warning"></use>' +
                    '</svg>' +
                    '<span class="slds-assistive-text">Warning</span>' +
                    '</span>' +
                    '<span>' + message + '</span>' +
                    '</div>' +
                    '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                    '</div>' +
                    '</div>';
            }
        }
        
        ul.appendChild(li);
    }

    //TODAY - Pushing the received message to chat window (Inbound Message)
    handleTodayInboundMessage(message, authorName, createdDate, createdTime, messageType, authorInitials, translatedMessage, imagePublicUrl) {
         console.log('handleTodayInboundMessage');
        //Attach Link Attribute
        var imageLink;
        if(messageType == 'image'){
          //imageLink = '<span> <a href=' + message + ' target="_blank">' + message + '</a></span>' ;
          imageLink = '<span> <a href=' + imagePublicUrl + ' target="_blank"> <img src="' + message + '" height="100px" width="100px"/></a></span>' ;
        }
        else{
           imageLink = '<span>' + message + '</span>';
        }

        var ul = this.template.querySelector('[data-id="todayChatList"]');
        var li = document.createElement("li")
        li.setAttribute("class", "slds-chat-listitem slds-chat-listitem_inbound");
        //Check if there is Translated Message
        if (translatedMessage != null && translatedMessage != undefined) {
            li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                '<div class="slds-chat-message__body">' +
                '<div class="slds-chat-message__text slds-chat-message__text_inbound" style="border:1px solid #c9c9c9;">' +
                imageLink +
                '</div>' +
                '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
                '<p class="slds-m-left_x-small slds-m-top_xx-small" style="color:grey;">  Translated message  </p>' +
                '<p class="slds-m-left_x-small slds-m-top_xx-small"> ' + translatedMessage + ' </p>' +
                '</span> </div>' +
                '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                '</div>' +
                '</div>';
        }
        else {
            li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                '<div class="slds-chat-message__body">' +
                '<div class="slds-chat-message__text slds-chat-message__text_inbound" style="border:1px solid #c9c9c9;">' +
                imageLink +
                '</div>' +
                '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                '</div>' +
                '</div>';
        }
        
        ul.appendChild(li);
    }

    //TODAY - Pushing the sent message to chat window (Outbound Message)
    handleTodayOutboundMessage(message, authorName, createdDate, createdTime, messageId, authorInitials, source, translatedMessage) {
        console.log('in handleTodayOutboundMessage');
        var ul = this.template.querySelector('[data-id="todayChatList"]');
        var li = document.createElement("li");
        li.setAttribute("class", "slds-chat-listitem slds-chat-listitem_outbound");
        if (messageId != null) {
            if (source == 'ai') {
                //Check if there is Translated Message
                if (translatedMessage != null && translatedMessage != undefined) {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound" style="background-color:grey;">' +
                        '<span>' + message + '</span>' +
                        '</div>' +
                        '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small"> <b> Translated Message </b> </p>' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small">' + translatedMessage + '</p>' +
                        '</span> </div>' +
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }
                else {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound" style="background-color:grey;">' +
                        '<span>' + message + '</span>' +
                        '</div>' +                       
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }
            } else {
                //Check if there is Translated Message
                if (translatedMessage != null && translatedMessage != undefined) {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound">' +
                        '<span>' + message + '</span>' +
                        '</div>' +
                        '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small"> <b> Translated Message </b> </p>' +
                        '<p class="slds-m-left_x-small slds-m-top_xx-small">' + translatedMessage + '</p>' +
                        '</span> </div>' +
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }
                else {
                    li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                        '<div class="slds-chat-message__body slds-m-right_x-small">' +
                        '<div class="slds-chat-message__text slds-chat-message__text_outbound">' +
                        '<span>' + message + '</span>' +
                        '</div>' +
                        '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                        '</div>' +
                        '</div>';
                }
            }
        }
        else {

            //Check if there is Translated Message
            if (translatedMessage != null && translatedMessage != undefined) {
                li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                    '<div class="slds-chat-message__body">' +
                    '<div class="slds-chat-message__text slds-chat-message__text_delivery-failure slds-m-right_x-small">' +
                    '<span class="slds-icon_container slds-icon-utility-error slds-chat-icon">' +
                    '<svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-icon-text-default" aria-hidden="true">' +
                    '<use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#warning"></use>' +
                    '</svg>' +
                    '<span class="slds-assistive-text">Warning</span>' +
                    '</span>' +
                    '<span>' + message + '</span>' +
                    '</div>' +
                    '<div class="slds-m-left_small slds-m-top_small" style="border-left:1px solid grey; background-color: light-grey;"> <span> ' +
                    '<p class="slds-m-left_x-small slds-m-top_xx-small"> <b> Translated Message </b> </p>' +
                    '<p class="slds-m-left_x-small slds-m-top_xx-small">' + translatedMessage + '</p>' +
                    '</span> </div>' +
                    '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                    '</div>' +
                    '</div>';
            }
            else {
                li.innerHTML = '<div class="slds-chat-message slds-m-top_small" style="max-width:85%;">' +
                    '<div class="slds-chat-message__body">' +
                    '<div class="slds-chat-message__text slds-chat-message__text_delivery-failure slds-m-right_x-small">' +
                    '<span class="slds-icon_container slds-icon-utility-error slds-chat-icon">' +
                    '<svg class="slds-icon slds-icon_x-small slds-icon-text-default slds-icon-text-default" aria-hidden="true">' +
                    '<use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#warning"></use>' +
                    '</svg>' +
                    '<span class="slds-assistive-text">Warning</span>' +
                    '</span>' +
                    '<span>' + message + '</span>' +
                    '</div>' +
                    '<div class="slds-chat-message__meta" aria-label="">' + authorName + ' • ' + createdDate + ' • ' + createdTime + '</div>' +
                    '</div>' +
                    '</div>';
            }
        }
        ul.appendChild(li);
    }

    
    //Show Opt Out User More Info Model 
    //Show Model Popup
    showOptOutModel() {
        this.isShowOptOutModel = true;
    }
    //Hide Model Popup
    hideOptoutModal() {
        this.isShowOptOutModel = false;
    }

    //Select SMS Template Model pop-up open
    selectSMSTemplate() {
        this.isShowModal = true;
    }
    //Select SMS Template Model pop-up close
    hideModalBox() {
        this.isShowModal = false;
    }

   //Template Message Event
    selectedTemplateMessage(event) {
        console.log('event.detail-',event.detail);
        if(event.detail=='Close Section Modal'){
            this.isShowModal = false;
        }else{
            this.inputMessage = event.detail;
            console.log('this.inputMessage--', this.inputMessage);
            this.isShowModal = false;
        }
    }
}