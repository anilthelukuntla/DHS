@RestResource(urlMapping='/msgraph/lifecycle/*')
/**
 * Receives Microsoft Graph lifecycle notifications, validates their client
 * state, and queues each valid notification for asynchronous processing.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.OperationWithLimitsInLoop')
global without sharing class MicrosoftGraphWebhookController {
    @HttpPost
    global static void receive() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String validationToken = request.params.get('validationToken');

        if (validationToken != null) {
            response.statusCode = 200;
            response.addHeader(
                'Content-Type',
                'text/plain; charset=utf-8'
            );
            response.responseBody = Blob.valueOf(validationToken);
            return;
        }

        Map<String, Object> envelope =
            (Map<String, Object>) JSON.deserializeUntyped(
                request.requestBody == null
                    ? '{}'
                    : request.requestBody.toString()
            );
        List<Object> notifications =
            (List<Object>) envelope.get('value');
        if (notifications == null || notifications.isEmpty()) {
            response.statusCode = 202;
            return;
        }

        Set<String> subscriptionIds = new Set<String>();
        for (Object value : notifications) {
            Map<String, Object> notification =
                (Map<String, Object>) value;
            if (notification.get('subscriptionId') != null) {
                subscriptionIds.add(
                    String.valueOf(notification.get('subscriptionId'))
                );
            }
        }

        Map<String, MS_Graph_Subscription__c> subscriptionsByGraphId =
            new Map<String, MS_Graph_Subscription__c>();
        Map<String, Object> subscriptionQueryBinds =
            new Map<String, Object>{
                'graphSubscriptionIds' => subscriptionIds
            };
        List<MS_Graph_Subscription__c> matchingSubscriptions =
            Database.queryWithBinds(
                'SELECT Graph_Subscription_ID__c, ' +
                'Client_State_Hash__c, Meeting_Schedule__c, Status__c ' +
                'FROM MS_Graph_Subscription__c ' +
                'WHERE Graph_Subscription_ID__c IN :graphSubscriptionIds',
                subscriptionQueryBinds,
                AccessLevel.SYSTEM_MODE
            );
        for (MS_Graph_Subscription__c subscription : matchingSubscriptions) {
            subscriptionsByGraphId.put(
                subscription.Graph_Subscription_ID__c,
                subscription
            );
        }

        for (Object value : notifications) {
            Map<String, Object> notification =
                (Map<String, Object>) value;
            String subscriptionId =
                stringValue(notification.get('subscriptionId'));
            MS_Graph_Subscription__c subscription =
                subscriptionsByGraphId.get(subscriptionId);
            if (
                subscription == null ||
                subscription.Status__c != 'Active' ||
                !clientStateMatches(
                    stringValue(notification.get('clientState')),
                    subscription.Client_State_Hash__c
                )
            ) {
                continue;
            }
            notification.put(
                '_salesforceScheduleId',
                subscription.Meeting_Schedule__c
            );
            System.enqueueJob(
                new MicrosoftGraphLifecycleQueueable(
                    JSON.serialize(notification)
                )
            );
        }
        response.statusCode = 202;
    }

    private static Boolean clientStateMatches(
        String clientState,
        String expectedHash
    ) {
        if (String.isBlank(clientState) || String.isBlank(expectedHash)) {
            return false;
        }
        String actualHash = EncodingUtil.convertToHex(
            Crypto.generateDigest(
                'SHA-256',
                Blob.valueOf(clientState)
            )
        ).toLowerCase();
        return actualHash == expectedHash.toLowerCase();
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}