@isTest
/** Exercises the existing DocuSignAPI_ behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.AvoidGlobalModifier, PMD.ApexDoc, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ExcessiveParameterList, PMD.NcssCount, PMD.UnusedLocalVariable')
global class DocuSignAPI_TEST {

    @IsTest static void testNewClass() {
    
    
        DocuSignAPI.SSN4InformationInput d01 = new DocuSignAPI.SSN4InformationInput();
        DocuSignAPI.EventNotification d02 = new DocuSignAPI.EventNotification();
        DocuSignAPI.ArrayOfServerTemplate d03 = new DocuSignAPI.ArrayOfServerTemplate();
        DocuSignAPI.ArrayOfTemplateReferenceFieldDataDataValue d04 = new DocuSignAPI.ArrayOfTemplateReferenceFieldDataDataValue();
        DocuSignAPI.CreateEnvelopeResponse_element d05 = new DocuSignAPI.CreateEnvelopeResponse_element();
        DocuSignAPI.SendEnvelopeResponse_element d06 = new DocuSignAPI.SendEnvelopeResponse_element();
        DocuSignAPI.ArrayOfTemplateReferenceRoleAssignment d07 = new DocuSignAPI.ArrayOfTemplateReferenceRoleAssignment();
        DocuSignAPI.Attachment d08 = new DocuSignAPI.Attachment();
        DocuSignAPI.SSN4Information d09 = new DocuSignAPI.SSN4Information();
        DocuSignAPI.IDCheckInformation d10 = new DocuSignAPI.IDCheckInformation();
        DocuSignAPI.Document d11 = new DocuSignAPI.Document();
        DocuSignAPI.ArrayOfTemplateReference d12 = new DocuSignAPI.ArrayOfTemplateReference();
        DocuSignAPI.RecipientStatus d13 = new DocuSignAPI.RecipientStatus();
        DocuSignAPI.CreateEnvelope_element d14 = new DocuSignAPI.CreateEnvelope_element();
        DocuSignAPI.Reminders d15 = new DocuSignAPI.Reminders();
        DocuSignAPI.CreateEnvelopeFromTemplates_element d16 = new DocuSignAPI.CreateEnvelopeFromTemplates_element();
        DocuSignAPI.ArrayOfCustomField d17 = new DocuSignAPI.ArrayOfCustomField();
        DocuSignAPI.ArrayOfRecipient1 d18 = new DocuSignAPI.ArrayOfRecipient1();
        DocuSignAPI.RequestRecipientToken_element d19 = new DocuSignAPI.RequestRecipientToken_element();
        DocuSignAPI.ArrayOfTab d20 = new DocuSignAPI.ArrayOfTab();
        DocuSignAPI.EnvelopeEvent d21 = new DocuSignAPI.EnvelopeEvent();
        DocuSignAPI.Recipient d22 = new DocuSignAPI.Recipient();
        DocuSignAPI.FormDataXfdf d23 = new DocuSignAPI.FormDataXfdf();
        DocuSignAPI.RecipientCaptiveInfo d24 = new DocuSignAPI.RecipientCaptiveInfo();
        DocuSignAPI.ArrayOfRecipientStatus d25 = new DocuSignAPI.ArrayOfRecipientStatus();
        DocuSignAPI.AuthenticationStatus d26 = new DocuSignAPI.AuthenticationStatus();
        DocuSignAPI.ArrayOfFormDataXfdfField d27 = new DocuSignAPI.ArrayOfFormDataXfdfField();
        DocuSignAPI.RecipientPhoneAuthentication d28 = new DocuSignAPI.RecipientPhoneAuthentication();
        DocuSignAPI.TemplateReferenceFieldDataDataValue d29 = new DocuSignAPI.TemplateReferenceFieldDataDataValue();
        DocuSignAPI.CreateEnvelopeFromTemplatesAndFormsResponse_element d30 = new DocuSignAPI.CreateEnvelopeFromTemplatesAndFormsResponse_element();
        DocuSignAPI.ArrayOfString1 d31 = new DocuSignAPI.ArrayOfString1();
        DocuSignAPI.ArrayOfDocumentStatus d32 = new DocuSignAPI.ArrayOfDocumentStatus();
        DocuSignAPI.CreateEnvelopeFromTemplatesResponse_element d33 = new DocuSignAPI.CreateEnvelopeFromTemplatesResponse_element();
        DocuSignAPI.SendEnvelope_element d34 = new DocuSignAPI.SendEnvelope_element();
        DocuSignAPI.RequestRecipientFaxToken_element d35 = new DocuSignAPI.RequestRecipientFaxToken_element();
        DocuSignAPI.DOBInformationInput d36 = new DocuSignAPI.DOBInformationInput();
        DocuSignAPI.RequestSenderTokenResponse_element d37 = new DocuSignAPI.RequestSenderTokenResponse_element();
        DocuSignAPI.InlineTemplate d38 = new DocuSignAPI.InlineTemplate();
        DocuSignAPI.RecipientSignatureInfo d39 = new DocuSignAPI.RecipientSignatureInfo();        
        DocuSignAPI.AddressInformationInput d40 = new DocuSignAPI.AddressInformationInput();        
        DocuSignAPI.ArrayOfRecipient d41 = new DocuSignAPI.ArrayOfRecipient();        
        DocuSignAPI.CreateEnvelopeFromTemplatesAndForms_element d42 = new DocuSignAPI.CreateEnvelopeFromTemplatesAndForms_element();        
        DocuSignAPI.EnvelopeInformation d43 = new DocuSignAPI.EnvelopeInformation();        
        DocuSignAPI.AddressInformation d44 = new DocuSignAPI.AddressInformation();        
        DocuSignAPI.ArrayOfTabStatus d45 = new DocuSignAPI.ArrayOfTabStatus();        
        DocuSignAPI.TemplateReferenceRoleAssignment d46 = new DocuSignAPI.TemplateReferenceRoleAssignment();        
        DocuSignAPI.Envelope d47 = new DocuSignAPI.Envelope();        
        DocuSignAPI.ArrayOfAttachment d48 = new DocuSignAPI.ArrayOfAttachment();        
        DocuSignAPI.Notification d49 = new DocuSignAPI.Notification();        
        DocuSignAPI.RequestSenderToken_element d50 = new DocuSignAPI.RequestSenderToken_element();        
        DocuSignAPI.CreateAndSendEnvelopeResponse_element d51 = new DocuSignAPI.CreateAndSendEnvelopeResponse_element();        
        DocuSignAPI.RequestRecipientTokenAuthenticationAssertion d52 = new DocuSignAPI.RequestRecipientTokenAuthenticationAssertion();        
        DocuSignAPI.SSN9InformationInput d53 = new DocuSignAPI.SSN9InformationInput();        
        DocuSignAPI.ServerTemplate d54 = new DocuSignAPI.ServerTemplate();        
        DocuSignAPI.RequestRecipientTokenResponse_element d55 = new DocuSignAPI.RequestRecipientTokenResponse_element();        
        DocuSignAPI.IDCheckInformationInput d56 = new DocuSignAPI.IDCheckInformationInput();        
        DocuSignAPI.TabStatus d57 = new DocuSignAPI.TabStatus();        
        DocuSignAPI.ArrayOfMatchBox d58 = new DocuSignAPI.ArrayOfMatchBox();        
        DocuSignAPI.SSN9Information d59 = new DocuSignAPI.SSN9Information();        
        DocuSignAPI.EnvelopeStatus d60 = new DocuSignAPI.EnvelopeStatus();        
        DocuSignAPI.ArrayOfEnvelopeEvent d61 = new DocuSignAPI.ArrayOfEnvelopeEvent();        
        DocuSignAPI.MatchBox d62 = new DocuSignAPI.MatchBox();        
        DocuSignAPI.TemplateReferenceFieldData d63 = new DocuSignAPI.TemplateReferenceFieldData();        
        DocuSignAPI.TemplateReference d64 = new DocuSignAPI.TemplateReference();        
        DocuSignAPI.CompositeTemplate d65 = new DocuSignAPI.CompositeTemplate();        
        DocuSignAPI.DOBInformation d66 = new DocuSignAPI.DOBInformation();        
        DocuSignAPI.DocumentStatus d67 = new DocuSignAPI.DocumentStatus();        
        DocuSignAPI.AnchorTab d68 = new DocuSignAPI.AnchorTab();        
        DocuSignAPI.EventResult d69 = new DocuSignAPI.EventResult();        
        DocuSignAPI.FormDataXfdfField d70 = new DocuSignAPI.FormDataXfdfField();        
        DocuSignAPI.PDFMetaDataTemplate d71 = new DocuSignAPI.PDFMetaDataTemplate();        
        DocuSignAPI.Tab  d72 = new DocuSignAPI.Tab ();        
        DocuSignAPI.ArrayOfInlineTemplate d73 = new DocuSignAPI.ArrayOfInlineTemplate();        
        DocuSignAPI.ArrayOfString d74 = new DocuSignAPI.ArrayOfString();        
        DocuSignAPI.VaultingDetails d75 = new DocuSignAPI.VaultingDetails();        
        DocuSignAPI.CustomField d76 = new DocuSignAPI.CustomField();        
        DocuSignAPI.Expirations d77 = new DocuSignAPI.Expirations();        
        DocuSignAPI.RecipientStatusEsignAgreementInformation d78 = new DocuSignAPI.RecipientStatusEsignAgreementInformation();        
        DocuSignAPI.VaultingOptions d79 = new DocuSignAPI.VaultingOptions();        
        DocuSignAPI.RequestRecipientTokenClientURLs d80 = new DocuSignAPI.RequestRecipientTokenClientURLs();        
        DocuSignAPI.CreateAndSendEnvelope_element d81 = new DocuSignAPI.CreateAndSendEnvelope_element();        
        DocuSignAPI.APIServiceSoap d82 = new DocuSignAPI.APIServiceSoap();        
        
        
   
    }

    @IsTest static void testApiServiceOperations() {
        Test.setMock(WebServiceMock.class, new DocuSignServiceMock());
        DocuSignAPI.APIServiceSoap service = new DocuSignAPI.APIServiceSoap();

        System.assertEquals(
            'sender-token',
            service.RequestSenderToken('envelope', 'account', 'return-url')
        , 'Assertion failed in DocuSignAPI_TEST at source line 100');
        System.assertEquals(
            'recipient-token',
            service.RequestRecipientToken(
                'envelope', 'client', 'User', 'user@example.com',
                new DocuSignAPI.RequestRecipientTokenAuthenticationAssertion(),
                new DocuSignAPI.RequestRecipientTokenClientURLs()
            )
        , 'Assertion failed in DocuSignAPI_TEST at source line 104');
        System.assertNotEquals(
            null,
            service.CreateEnvelope(new DocuSignAPI.Envelope())
        , 'Assertion failed in DocuSignAPI_TEST at source line 112');
        System.assertNotEquals(
            null,
            service.CreateAndSendEnvelope(new DocuSignAPI.Envelope())
        , 'Assertion failed in DocuSignAPI_TEST at source line 116');
    }

    private class DocuSignServiceMock implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNamespace,
            String responseName,
            String responseType
        ) {
            if (responseName == 'RequestSenderTokenResponse') {
                DocuSignAPI.RequestSenderTokenResponse_element result =
                    new DocuSignAPI.RequestSenderTokenResponse_element();
                result.RequestSenderTokenResult = 'sender-token';
                response.put('response_x', result);
            } else if (responseName == 'RequestRecipientTokenResponse') {
                DocuSignAPI.RequestRecipientTokenResponse_element result =
                    new DocuSignAPI.RequestRecipientTokenResponse_element();
                result.RequestRecipientTokenResult = 'recipient-token';
                response.put('response_x', result);
            } else if (responseName == 'CreateEnvelopeResponse') {
                DocuSignAPI.CreateEnvelopeResponse_element result =
                    new DocuSignAPI.CreateEnvelopeResponse_element();
                result.CreateEnvelopeResult = new DocuSignAPI.EnvelopeStatus();
                response.put('response_x', result);
            } else {
                DocuSignAPI.CreateAndSendEnvelopeResponse_element result =
                    new DocuSignAPI.CreateAndSendEnvelopeResponse_element();
                result.CreateAndSendEnvelopeResult =
                    new DocuSignAPI.EnvelopeStatus();
                response.put('response_x', result);
            }
        }
    }

    /*@IsTest static void testAPIService() {

        DocuSignAPI.APIServiceSoap apiService = new DocuSignAPI.APIServiceSoap();
        
        Test.setMock(WebServiceMock.class, new AG_WebServiceMockImpl());
        
        apiservice.RequestDocumentPDFsRecipientsView('', '', '');
        apiService.CreateEnvelopeFromTemplates(Null, Null, Null, False);
        apiService.RequestTemplate('', False);
        apiService.MoveEnvelopes(Null);
        apiService.PurgeDocuments('');
        apiService.CreateAndSendEnvelope(Null);
        apiService.RequestStatusWithDocumentFields('');
        apiService.RequestRecipientFaxPDF('', '', '', '', Null);
        apiService.RequestPDFWithCert('', False);
        apiService.GetRecipientEsignList('', '', '', '');
        apiService.SaveTemplate(Null);
        apiService.GetFolderList(Null);
        apiService.CorrectAndResendEnvelope(Null);
        apiService.RequestPDFWithOptions('', Null);
        apiService.RequestRecipientToken('', '', '', '', Null, Null);
        apiService.RequestPDF('');
        apiService.UploadTemplate('', '', False);
        apiService.DeleteEnvelopes(Null);
        apiService.CreateEnvelopeFromTemplatesAndForms(Null, Null, False);
        apiService.GetConnectFailures(Null);
        apiService.RequestStatusChanges(Null);
        apiService.Ping();
        apiService.RequestTemplates('', False);
        apiService.RemoveAddressBookItems(Null, False);
        apiService.RequestTemplateList(Null, False);
        apiService.GetAddressBookItems('');
        apiService.RequestSenderToken('', '', '');
        apiService.RequestCertificate('');
        apiservice.GetSharedAccess('', Null);
        apiService.PublishConnectFailures(Null);
        apiService.CreateEnvelope(Null);
        apiService.RequestPDFsWithOptions('', Null);
        apiService.GetStatusInDocuSignConnectFormat('');
        apiService.RequestStatusEx('');
        apiService.SetSharedAccess(Null);
        apiService.AcknowledgeAuthoritativeCopyExport('', '', '');
        apiService.RequestStatusesEx(Null);
        apiService.RequestPDFNoWaterMark('');
        apiService.RequestStatuses(Null);
        apiService.ExportAuthoritativeCopy('');
        apiService.RequestPDFRecipientsView('', '', '', Null);
        apiService.EnvelopeAuditEvents('');
        apiservice.RequestDocumentPDFs('');
        apiservice.SynchEnvelope('', '', False);
        apiservice.RequestTemplateListWithDocumentFields(Null, False);
        apiservice.RequestEnvelopeWithDocumentFields('', False);
        apiservice.GetFolderItems(Null);
        apiservice.SendEnvelope('', '');
        apiservice.RequestDocumentPDFsEx('');
        apiservice.GetRecipientList('', '');
        apiservice.GetAccountMembershipFeaturesList('');
        apiservice.VoidEnvelope('', '');
        apiservice.RequestRecipientFaxToken('', '', '', '', Null, Null);
        apiService.RequestTemplateWithDocumentFields('', False);
        apiService.GetAuthenticationToken('');
        apiService.GetAccountBrands('');
        apiService.DeleteCaptiveRecipientsSignatures('', Null);
        apiService.PurgeDocumentsAndMetaData('');
        apiservice.RequestStatus('');
        apiservice.TransferEnvelope('', '', '');
        apiservice.UpdateAddressBookItems(Null, False);
        apiservice.RequestStatusCodes(Null);
        apiservice.CreateAccountBrands('', Null);
        apiservice.RequestStatusesWithDocumentFields(Null);
        apiservice.GetAccountSettingsList('');
        apiservice.RequestCorrectToken('', False, '');
        apiservice.DeleteAccountBrands('', Null);

    }*/
}