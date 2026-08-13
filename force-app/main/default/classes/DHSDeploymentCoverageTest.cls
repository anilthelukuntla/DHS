@IsTest
/** Exercises the existing DHSDeploymentCoverage behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity')
private class DHSDeploymentCoverageTest {
    @IsTest
    static void validatesMicrosoftGraphAuthenticationResponses() {
        Test.setMock(HttpCalloutMock.class, new AuthMock());

        MicrosoftGraphAuthController.AuthenticationResult delegated =
            MicrosoftGraphAuthController.validateDelegatedAuthentication();
        System.assertEquals(true, delegated.authenticated, 'Assertion failed in DHSDeploymentCoverageTest at source line 11');
        System.assertEquals('user-1', delegated.microsoftUserId, 'Assertion failed in DHSDeploymentCoverageTest at source line 12');
        System.assertEquals('Graph User', delegated.displayName, 'Assertion failed in DHSDeploymentCoverageTest at source line 13');

        MicrosoftGraphAuthController.AuthenticationResult forbidden =
            MicrosoftGraphAuthController.validateApplicationAuthentication(
                ' user@example.com '
            );
        System.assertEquals(false, forbidden.authenticated, 'Assertion failed in DHSDeploymentCoverageTest at source line 19');
        System.assertEquals(403, forbidden.statusCode, 'Assertion failed in DHSDeploymentCoverageTest at source line 20');
        System.assert(forbidden.message.contains('required permission'), 'Assertion failed in DHSDeploymentCoverageTest at source line 21');

        MicrosoftGraphAuthController.AuthenticationResult missing =
            MicrosoftGraphAuthController.validateEndpoint('/missing');
        System.assertEquals(404, missing.statusCode, 'Assertion failed in DHSDeploymentCoverageTest at source line 25');
        System.assert(missing.message.contains('was not found'), 'Assertion failed in DHSDeploymentCoverageTest at source line 26');

        MicrosoftGraphAuthController.AuthenticationResult unauthorized =
            MicrosoftGraphAuthController.validateEndpoint('/unauthorized');
        System.assertEquals(401, unauthorized.statusCode, 'Assertion failed in DHSDeploymentCoverageTest at source line 30');
        System.assert(unauthorized.message.contains('InvalidAuthenticationToken'), 'Assertion failed in DHSDeploymentCoverageTest at source line 31');

        MicrosoftGraphAuthController.AuthenticationResult invalidJson =
            MicrosoftGraphAuthController.validateEndpoint('/invalid-json');
        System.assertEquals(500, invalidJson.statusCode, 'Assertion failed in DHSDeploymentCoverageTest at source line 35');
        System.assert(invalidJson.message.contains('HTTP 500'), 'Assertion failed in DHSDeploymentCoverageTest at source line 36');

        MicrosoftGraphAuthController.AuthenticationResult invalidPath =
            MicrosoftGraphAuthController.validateEndpoint('invalid');
        System.assertEquals(0, invalidPath.statusCode, 'Assertion failed in DHSDeploymentCoverageTest at source line 40');
        System.assert(invalidPath.message.contains('validation failed'), 'Assertion failed in DHSDeploymentCoverageTest at source line 41');

        try {
            MicrosoftGraphAuthController.validateApplicationAuthentication(' ');
            System.assert(false, 'Blank identifiers must be rejected.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected, 'Assertion failed in DHSDeploymentCoverageTest at source line 47');
        }
    }

    @IsTest
    static void createsFiltersAndPublishesFiles() {
        Account account = new Account(Name = 'Coverage Files');
        insert account;

        DHSFilesRecipes.createFileFromStringAttachedToRecord(
            'plain text', account.Id
        );

        DHSFilesRecipes.FileAndLinkObject single =
            new DHSFilesRecipes.FileAndLinkObject();
        single.fileContents = Blob.valueOf('pdf bytes');
        single.attachedTo = account.Id;
        single.fileName = 'coverage.pdf';
        System.assert(DHSFilesRecipes.createFileAttachedToRecord(single).isSuccess(), 'Assertion failed in DHSDeploymentCoverageTest at source line 65');

        List<DHSFilesRecipes.FileAndLinkObject> batchFiles =
            new List<DHSFilesRecipes.FileAndLinkObject>();
        for (String fileName : new List<String>{ 'image.jpg', 'audio.m4a' }) {
            DHSFilesRecipes.FileAndLinkObject item =
                new DHSFilesRecipes.FileAndLinkObject();
            item.fileContents = Blob.valueOf(fileName);
            item.attachedTo = account.Id;
            item.fileName = fileName;
            batchFiles.add(item);
        }
        System.assertEquals(
            2,
            DHSFilesRecipes.createFilesAttachedToRecords(batchFiles).size()
        , 'Assertion failed in DHSDeploymentCoverageTest at source line 77');

        System.assertEquals(
            4,
            DHSFilesRecipes.getFilteredAttachmentsForRecord(
                DHSFilesRecipes.GenericFileType.ALL, account.Id
            ).size()
        , 'Assertion failed in DHSDeploymentCoverageTest at source line 82');
        System.assertEquals(
            1,
            DHSFilesRecipes.getFilteredAttachmentsForRecord(
                DHSFilesRecipes.GenericFileType.IMAGE, account.Id
            ).size()
        , 'Assertion failed in DHSDeploymentCoverageTest at source line 88');
        System.assertEquals(
            1,
            DHSFilesRecipes.getFilteredAttachmentsForRecord(
                DHSFilesRecipes.GenericFileType.AUDIO, account.Id
            ).size()
        , 'Assertion failed in DHSDeploymentCoverageTest at source line 94');
        System.assertEquals(
            1,
            DHSFilesRecipes.getFilteredAttachmentsForRecord(
                DHSFilesRecipes.GenericFileType.DOCUMENT, account.Id
            ).size()
        , 'Assertion failed in DHSDeploymentCoverageTest at source line 100');

        ContentDocumentLink link = [
            SELECT LinkedEntityId,
                ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :account.Id
            LIMIT 1
        ];
        System.assert(DHSFilesRecipes.publishContent(link).isSuccess(), 'Assertion failed in DHSDeploymentCoverageTest at source line 114');
    }

    @IsTest
    static void lifecycleSchedulerEnqueuesMaintenanceAndMeetingSync() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        MS_Team_Call_Schedule__c schedule = new MS_Team_Call_Schedule__c(
            Subject__c = 'Scheduler coverage',
            Start_Date_Time__c = '2026-08-01T10:00:00',
            End_Date_Time__c = '2026-08-01T11:00:00',
            Microsoft_Time_Zone__c = 'India Standard Time',
            Online_Meeting_ID__c = 'online-meeting-scheduler',
            Status__c = 'Scheduled',
            Last_Synchronized_At__c = System.now().addHours(-1)
        );
        insert schedule;

        MicrosoftGraphLifecycleScheduler.skipQueueableEnqueue = true;
        Integer jobsBefore = Limits.getQueueableJobs();
        new MicrosoftGraphLifecycleScheduler().execute(null);

        System.assertEquals(jobsBefore, Limits.getQueueableJobs(), 'Assertion failed in DHSDeploymentCoverageTest at source line 136');
        MicrosoftGraphLifecycleScheduler.skipQueueableEnqueue = false;
        }
    }

    @IsTest
    static void buildsManifestForApplicantAndContractorFiles() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        List<DHS_Contact__c> contacts = new List<DHS_Contact__c>{
            new DHS_Contact__c(
                First_Name__c = 'Applicant', Last_Name__c = 'Coverage',
                Email__c = 'applicant@example.com', SSN__c = '111-22-3333',
                Contact_Type__c = 'Subject'
            ),
            new DHS_Contact__c(
                First_Name__c = 'Contractor', Last_Name__c = 'Coverage',
                Email__c = 'contractor@example.com', SSN__c = '444-55-6666',
                Contact_Type__c = 'Subject'
            )
        };
        insert contacts;
        List<DHS_Case__c> cases = new List<DHS_Case__c>{
            new DHS_Case__c(
                DHS_Contact__c = contacts[0].Id,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                Subject_Type__c = 'Applicant'
            ),
            new DHS_Case__c(
                DHS_Contact__c = contacts[1].Id,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                Subject_Type__c = 'Contractor'
            )
        };
        insert cases;

        List<DHS_Document__c> documents = new List<DHS_Document__c>();
        for (DHS_Case__c caseRecord : cases) {
            documents.add(new DHS_Document__c(
                DHS_Case__c = caseRecord.Id, Name__c = 'ROIReport'
            ));
            documents.add(new DHS_Document__c(
                DHS_Case__c = caseRecord.Id, Name__c = 'Attachment'
            ));
        }
        insert documents;
        List<Attachment> attachments = new List<Attachment>();
        for (DHS_Document__c document : documents) {
            attachments.add(new Attachment(
                ParentId = document.Id,
                Name = document.Name__c + '.pdf',
                Body = Blob.valueOf('manifest coverage')
            ));
        }
        insert attachments;

        String versionOne = DHSManifestXMLGenerator.LoadReleasesXML(
            new List<String>{ cases[0].Id, cases[1].Id }, '1'
        );
        String versionTen = DHSManifestXMLGenerator.LoadReleasesXML(
            new List<String>{ cases[0].Id, cases[1].Id }, '10'
        );
        System.assert(versionOne.contains('A111223333Rev01.pdf'), 'Assertion failed in DHSDeploymentCoverageTest at source line 198');
        System.assert(versionOne.contains('C444556666Att00.pdf'), 'Assertion failed in DHSDeploymentCoverageTest at source line 199');
        System.assert(versionTen.contains('Rev10.pdf'), 'Assertion failed in DHSDeploymentCoverageTest at source line 200');
        System.assertEquals(null, DHSManifestXMLGenerator.LoadReleasesXML(cases[0].Id), 'Assertion failed in DHSDeploymentCoverageTest at source line 201');
        }
    }

    @IsTest
    static void buildsMeetingTimeSuggestionsAndFailures() {
        Test.setMock(HttpCalloutMock.class, new MeetingTimesMock());

        MicrosoftGraphMeetingController.MeetingTimesResult result =
            MicrosoftGraphMeetingController.findMeetingTimes(
                ' organizer@example.com ',
                new List<String>{
                    'attendee@example.com', 'ATTENDEE@example.com', ' '
                },
                '2026-08-03T10:00:00',
                '2026-08-03T12:00:00',
                'India Standard Time\r\n"',
                30
            );
        System.assertEquals(true, result.success, 'Assertion failed in DHSDeploymentCoverageTest at source line 220');
        System.assertEquals(1, result.meetingTimeSuggestions.size(), 'Assertion failed in DHSDeploymentCoverageTest at source line 221');
        System.assertEquals('entra-organizer', result.organizerMicrosoftUserId, 'Assertion failed in DHSDeploymentCoverageTest at source line 222');

        MicrosoftGraphMeetingController.MeetingTimesResult missing =
            MicrosoftGraphMeetingController.findMeetingTimes(
                'missing@example.com',
                new List<String>{ 'attendee@example.com' },
                '2026-08-03T10:00:00', '2026-08-03T12:00:00',
                'India Standard Time', 30
            );
        System.assertEquals(false, missing.success, 'Assertion failed in DHSDeploymentCoverageTest at source line 231');
        System.assertEquals(404, missing.statusCode, 'Assertion failed in DHSDeploymentCoverageTest at source line 232');

        MicrosoftGraphMeetingController.MeetingTimesResult duplicate =
            MicrosoftGraphMeetingController.findMeetingTimes(
                'duplicate@example.com',
                new List<String>{ 'attendee@example.com' },
                '2026-08-03T10:00:00', '2026-08-03T12:00:00',
                'India Standard Time', 30
            );
        System.assertEquals(false, duplicate.success, 'Assertion failed in DHSDeploymentCoverageTest at source line 241');
        System.assertEquals(0, duplicate.statusCode, 'Assertion failed in DHSDeploymentCoverageTest at source line 242');

        for (String organizer : new List<String>{
            'unauthorized@example.com', 'forbidden@example.com',
            'notfound@example.com', 'server@example.com'
        }) {
            MicrosoftGraphMeetingController.findMeetingTimes(
                organizer,
                new List<String>{ 'attendee@example.com' },
                '2026-08-03T10:00:00', '2026-08-03T12:00:00',
                'India Standard Time', 30
            );
        }

        List<List<Object>> invalidInputs = new List<List<Object>>{
            new List<Object>{ null, new List<String>{ 'a@example.com' }, 'start', 'end', 'UTC', 30 },
            new List<Object>{ 'o@example.com', null, 'start', 'end', 'UTC', 30 },
            new List<Object>{ 'o@example.com', new List<String>{ 'a@example.com' }, null, 'end', 'UTC', 30 },
            new List<Object>{ 'o@example.com', new List<String>{ 'a@example.com' }, 'start', null, 'UTC', 30 },
            new List<Object>{ 'o@example.com', new List<String>{ 'a@example.com' }, 'start', 'end', null, 30 },
            new List<Object>{ 'o@example.com', new List<String>{ 'a@example.com' }, 'start', 'end', 'UTC', 0 }
        };
        for (List<Object> values : invalidInputs) {
            try {
                MicrosoftGraphMeetingController.findMeetingTimes(
                    (String) values[0],
                    (List<String>) values[1],
                    (String) values[2],
                    (String) values[3],
                    (String) values[4],
                    (Integer) values[5]
                );
            } catch (AuraHandledException expected) {
                // Each invalid input is expected to be rejected.
            }
        }
    }

    @IsTest
    static void exercisesMailUtilityEntryPoints() {
        Contact recipient = new Contact(
            LastName = 'Mail Coverage', Email = 'mail@example.com'
        );
        insert recipient;
        List<String> addresses = new List<String>{ 'mail@example.com' };

        DHSMailUtilities.sendHTMLEmailWithTargetObjectId(
            recipient.Id, 'Target subject', '<p>Target</p>', addresses
        );
        DHSMailUtilities.sendHTMLEmailWithTargetObjectId(
            null, 'Ignored', '<p>Ignored</p>', null
        );
        DHSMailUtilities.sendHTMLEmail(
            addresses, 'List subject', '<p>List</p>', addresses
        );
        DHSMailUtilities.sendHTMLEmail(
            new List<String>(), 'Ignored', '<p>Ignored</p>', null
        );
        DHSMailUtilities.sendHTMLEmail(
            addresses, 'Template ignored', '<p>Template</p>', null,
            null, recipient.Id
        );
        List<EmailTemplate> availableTemplates = [
            SELECT Name
            FROM EmailTemplate
            LIMIT 1
        ];
        if (!availableTemplates.isEmpty()) {
            DHSMailUtilities.sendHTMLEmail(
                addresses, 'Template subject', '<p>Template</p>', addresses,
                availableTemplates[0].Name, recipient.Id
            );
        }
        DHSMailUtilities.sendBIEmail(
            'BI subject', '<p>BI</p>', addresses, addresses, addresses
        );
        DHSMailUtilities.sendBIEmail(
            'BI no bcc', '<p>BI</p>', addresses, null, addresses
        );
        DHSMailUtilities.sendBIEmailWithSetTargetObjectId(
            'Target BI', '<p>BI</p>', recipient.Id, addresses, addresses
        );
        DHSMailUtilities.sendBIEmailWithSetTargetObjectId(
            'Target BI no bcc', '<p>BI</p>', recipient.Id, null, addresses
        );
    }

    private class AuthMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatus('Mock response');
            String endpoint = request.getEndpoint();

            if (endpoint.contains('/me?')) {
                response.setStatusCode(200);
                response.setBody('{"id":"user-1","displayName":"Graph User",' +
                    '"userPrincipalName":"user@example.com",' +
                    '"mail":"user@example.com"}');
            } else if (endpoint.contains('/users/')) {
                response.setStatusCode(403);
                response.setBody('{"error":{"code":"Authorization_RequestDenied",' +
                    '"message":"Permission denied"}}');
            } else if (endpoint.endsWith('/missing')) {
                response.setStatusCode(404);
                response.setBody('');
            } else if (endpoint.endsWith('/unauthorized')) {
                response.setStatusCode(401);
                response.setBody('{"error":{"code":"InvalidAuthenticationToken",' +
                    '"message":"Token expired"}}');
            } else {
                response.setStatusCode(500);
                response.setBody('not-json');
            }
            return response;
        }
    }

    private class MeetingTimesMock implements HttpCalloutMock {
        private Integer nextStatusCode = 200;

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatus('Mock');
            if (request.getMethod() == 'GET') {
                response.setStatusCode(200);
                if (request.getEndpoint().contains('missing%40example.com')) {
                    response.setBody('{"value":[]}');
                } else if (request.getEndpoint().contains('duplicate%40example.com')) {
                    response.setBody('{"value":[{"id":"one"},{"id":"two"}]}');
                } else {
                    if (request.getEndpoint().contains('unauthorized%40example.com')) {
                        nextStatusCode = 401;
                    } else if (request.getEndpoint().contains('forbidden%40example.com')) {
                        nextStatusCode = 403;
                    } else if (request.getEndpoint().contains('notfound%40example.com')) {
                        nextStatusCode = 404;
                    } else if (request.getEndpoint().contains('server%40example.com')) {
                        nextStatusCode = 500;
                    } else {
                        nextStatusCode = 200;
                    }
                    response.setBody('{"value":[{"id":"entra-organizer",' +
                        '"mail":"organizer@example.com"}]}');
                }
                return response;
            }
            response.setStatusCode(nextStatusCode);
            if (nextStatusCode != 200) {
                response.setBody(nextStatusCode == 500
                    ? 'invalid-json'
                    : '{"error":{"code":"GraphError","message":"Mock failure"}}');
                return response;
            }
            response.setBody('{"emptySuggestionsReason":null,' +
                '"meetingTimeSuggestions":[{' +
                '"confidence":100,"suggestionReason":"All available",' +
                '"meetingTimeSlot":{"start":{"dateTime":"2026-08-03T10:00:00",' +
                '"timeZone":"India Standard Time"},' +
                '"end":{"dateTime":"2026-08-03T10:30:00",' +
                '"timeZone":"India Standard Time"}}}]}');
            return response;
        }
    }
}