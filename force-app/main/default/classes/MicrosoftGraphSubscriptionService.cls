/** Retains the existing MicrosoftGraphSubscriptionService integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.ExcessiveParameterList, PMD.ApexCRUDViolation')
public without sharing class MicrosoftGraphSubscriptionService {
    private static final Integer EXPIRATION_MINUTES = 4200;

    @AuraEnabled
    public static List<Id> createLifecycleSubscriptions(
        Id scheduleId,
        String notificationUrl,
        String lifecycleUrl,
        String encryptionCertificate,
        String encryptionCertificateId
    ) {
        validateHttpsUrl(notificationUrl, 'Notification URL');
        if (String.isNotBlank(lifecycleUrl)) {
            validateHttpsUrl(lifecycleUrl, 'Lifecycle URL');
        }
        MS_Team_Call_Schedule__c schedule = [
            SELECT
                Id,
                Graph_Event_ID__c,
                Online_Meeting_ID__c,
                Teams_Join_URL__c
            FROM MS_Team_Call_Schedule__c
            WHERE Id = :scheduleId
            LIMIT 1
        ];
        if (String.isBlank(schedule.Online_Meeting_ID__c)) {
            throw new AuraHandledException(
                'The Teams online meeting ID has not been resolved.'
            );
        }

        List<MS_Graph_Subscription__c> subscriptionsToInsert =
            new List<MS_Graph_Subscription__c>();
        if (!hasActiveCalendarSubscription()) {
            subscriptionsToInsert.add(
                createSubscription(
                    null,
                    'me/events',
                    'created,updated,deleted',
                    notificationUrl,
                    lifecycleUrl,
                    null,
                    null,
                    false
                )
            );
        }

        String onlineMeetingResource =
            'communications/onlineMeetings/' +
            schedule.Online_Meeting_ID__c;
        subscriptionsToInsert.add(
            createSubscription(
                schedule.Id,
                onlineMeetingResource + '/transcripts',
                'created',
                notificationUrl,
                lifecycleUrl,
                encryptionCertificate,
                encryptionCertificateId,
                false
            )
        );
        subscriptionsToInsert.add(
            createSubscription(
                schedule.Id,
                onlineMeetingResource + '/recordings',
                'created',
                notificationUrl,
                lifecycleUrl,
                encryptionCertificate,
                encryptionCertificateId,
                false
            )
        );

        if (
            String.isNotBlank(schedule.Teams_Join_URL__c) &&
            String.isNotBlank(encryptionCertificate) &&
            String.isNotBlank(encryptionCertificateId)
        ) {
            String callEventResource =
                '/communications/onlineMeetings(joinWebUrl=\'' +
                schedule.Teams_Join_URL__c.replace('\'', '\'\'') +
                '\')/meetingCallEvents';
            subscriptionsToInsert.add(
                createSubscription(
                    schedule.Id,
                    callEventResource,
                    'updated',
                    notificationUrl,
                    lifecycleUrl,
                    encryptionCertificate,
                    encryptionCertificateId,
                    true
                )
            );
        }
        Database.insert(
            subscriptionsToInsert,
            AccessLevel.SYSTEM_MODE
        );
        List<Id> createdSubscriptionIds = new List<Id>();
        for (
            MS_Graph_Subscription__c subscription :
            subscriptionsToInsert
        ) {
            createdSubscriptionIds.add(subscription.Id);
        }
        return createdSubscriptionIds;
    }

    public static void renewExpiringSubscriptions() {
        Datetime renewalCutoff = System.now().addHours(24);
        List<MS_Graph_Subscription__c> subscriptions = [
            SELECT
                Id,
                Graph_Subscription_ID__c,
                Expiration__c,
                Status__c
            FROM MS_Graph_Subscription__c
            WHERE Status__c = 'Active'
              AND Expiration__c <= :renewalCutoff
            LIMIT 50
        ];
        for (MS_Graph_Subscription__c subscription : subscriptions) {
            Datetime newExpiration =
                System.now().addMinutes(EXPIRATION_MINUTES);
            try {
                Map<String, Object> responseData =
                    MicrosoftGraphClient.requireJson(
                        MicrosoftGraphClient.patch(
                            '/subscriptions/' +
                            MicrosoftGraphClient.encodePath(
                                subscription.Graph_Subscription_ID__c
                            ),
                            new Map<String, Object>{
                                'expirationDateTime' =>
                                    formatGraphDateTime(newExpiration)
                            }
                        ),
                        new Set<Integer>{ 200 },
                        'Graph subscription renewal'
                    );
                subscription.Expiration__c =
                    MicrosoftGraphClient.parseDateTime(
                        responseData.get('expirationDateTime')
                    );
                subscription.Status__c = 'Active';
                subscription.Last_Error__c = null;
            } catch (Exception exceptionValue) {
                subscription.Status__c = 'Renewal Failed';
                subscription.Last_Error__c =
                    exceptionValue.getMessage();
            }
        }
        if (!subscriptions.isEmpty()) {
            Database.update(subscriptions, AccessLevel.SYSTEM_MODE);
        }
    }

    private static MS_Graph_Subscription__c createSubscription(
        Id scheduleId,
        String resource,
        String changeType,
        String notificationUrl,
        String lifecycleUrl,
        String encryptionCertificate,
        String encryptionCertificateId,
        Boolean requireRichNotification
    ) {
        String clientState = EncodingUtil.convertToHex(
            Crypto.generateAesKey(256)
        ).toLowerCase();
        Datetime expiration =
            System.now().addMinutes(EXPIRATION_MINUTES);
        Map<String, Object> payload = new Map<String, Object>{
            'changeType' => changeType,
            'notificationUrl' => notificationUrl,
            'resource' => resource,
            'expirationDateTime' => formatGraphDateTime(expiration),
            'clientState' => clientState
        };
        if (String.isNotBlank(lifecycleUrl)) {
            payload.put('lifecycleNotificationUrl', lifecycleUrl);
        }
        if (
            String.isNotBlank(encryptionCertificate) &&
            String.isNotBlank(encryptionCertificateId) &&
            requireRichNotification
        ) {
            payload.put('includeResourceData', true);
            payload.put(
                'encryptionCertificate',
                encryptionCertificate
            );
            payload.put(
                'encryptionCertificateId',
                encryptionCertificateId
            );
        }

        Map<String, Object> responseData =
            MicrosoftGraphClient.requireJson(
                MicrosoftGraphClient.post('/subscriptions', payload),
                new Set<Integer>{ 201 },
                'Graph subscription creation'
            );
        MS_Graph_Subscription__c subscription =
            new MS_Graph_Subscription__c(
                Graph_Subscription_ID__c =
                    stringValue(responseData.get('id')),
                Resource__c = resource,
                Change_Type__c = changeType,
                Expiration__c =
                    MicrosoftGraphClient.parseDateTime(
                        responseData.get('expirationDateTime')
                    ),
                Client_State_Hash__c = hashValue(clientState),
                Notification_URL__c = notificationUrl,
                Lifecycle_URL__c = lifecycleUrl,
                Meeting_Schedule__c = scheduleId,
                Status__c = 'Active'
            );
        return subscription;
    }

    private static Boolean hasActiveCalendarSubscription() {
        Datetime currentTime = System.now();
        List<MS_Graph_Subscription__c> activeSubscriptions =
            Database.queryWithBinds(
                'SELECT Resource__c FROM MS_Graph_Subscription__c ' +
                'WHERE Status__c = \'Active\' ' +
                'AND Expiration__c > :currentTime',
                new Map<String, Object>{
                    'currentTime' => currentTime
                },
                AccessLevel.SYSTEM_MODE
            );
        for (MS_Graph_Subscription__c subscription : activeSubscriptions) {
            if (subscription.Resource__c == 'me/events') {
                return true;
            }
        }
        return false;
    }

    private static void validateHttpsUrl(String value, String label) {
        if (
            String.isBlank(value) ||
            !value.trim().toLowerCase().startsWith('https://')
        ) {
            throw new AuraHandledException(
                label + ' must be a public HTTPS URL.'
            );
        }
    }

    private static String formatGraphDateTime(Datetime value) {
        return value.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }

    private static String hashValue(String value) {
        return EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(value))
        ).toLowerCase();
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}