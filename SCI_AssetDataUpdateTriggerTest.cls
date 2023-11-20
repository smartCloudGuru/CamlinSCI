@isTest
private class SCI_AssetDataUpdateTriggerTest {
    private static Long LAST_POINT_TIMESTAMP = 1647252722000L;
    private static String CB_MODEL_VALUE = 'Model 3';

    private static Circuit_Breaker__c createCircuitBreaker() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Location__c location = new Asset_Location__c(Name = 'Location', Company__c = company.Id);
        insert location;

        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'CB 1',
            Company__c = company.Id,
            Location__c = location.Id,
            Circuit_Breaker_ID__c = 'CB_1'
        );
        insert cb;

        return [SELECT Asset_ID__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
    }

    private static Transformer__c createTransformer() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Location__c location = new Asset_Location__c(
            Name = 'Location',
            Company__c = company.Id,
            Site_ID__c = 'LocationId'
        );
        insert location;

        Transformer__c t = new Transformer__c(
            Name = 'T1',
            Company__c = company.Id,
            Location__c = location.Id,
            Transformer_ID__c = 'T1'
        );
        insert t;

        return [SELECT Asset_ID__c FROM Transformer__c WHERE Id = :t.Id];
    }

    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_Asset_Data_onCircuitBreaker() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event1 = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'Asset_Data',
            Data__c = '{"timestamp":' + LAST_POINT_TIMESTAMP + '}'
        );
        SCI_Asset_Data_Update__e event2 = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'Asset_Data',
            Data__c = '{"timestamp":' + (LAST_POINT_TIMESTAMP - 1000) + '}'
        );

        Database.SaveResult sr1 = EventBus.publish(event1);
        Database.SaveResult sr2 = EventBus.publish(event2);

        Test.stopTest();

        System.assertEquals(true, sr1.isSuccess());
        System.assertEquals(true, sr2.isSuccess());

        cb = [SELECT Last_Point_Time__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(LAST_POINT_TIMESTAMP, cb.Last_Point_Time__c);
    }

    @isTest
    static void test_Asset_Data_onTransformer() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        Transformer__c t = createTransformer();

        SCI_Asset_Data_Update__e event1 = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Transformer',
            AssetId__c = t.Asset_ID__c,
            Data_Type__c = 'Asset_Data',
            Data__c = '{"timestamp":' + LAST_POINT_TIMESTAMP + '}'
        );
        SCI_Asset_Data_Update__e event2 = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Transformer',
            AssetId__c = t.Asset_ID__c,
            Data_Type__c = 'Asset_Data',
            Data__c = '{"timestamp":' + (LAST_POINT_TIMESTAMP - 1000) + '}'
        );

        Database.SaveResult sr1 = EventBus.publish(event1);
        Database.SaveResult sr2 = EventBus.publish(event2);

        Test.stopTest();

        System.assertEquals(true, sr1.isSuccess());
        System.assertEquals(true, sr2.isSuccess());

        t = [SELECT Last_Point_Time__c FROM Transformer__c WHERE Id = :t.Id];
        System.assertEquals(LAST_POINT_TIMESTAMP, t.Last_Point_Time__c);
    }

    @isTest
    static void test_ML_Data_onCircuitBreaker() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{' +
                '"timestamp":' +
                LAST_POINT_TIMESTAMP +
                ',"cbModel":"' +
                CB_MODEL_VALUE +
                '",' +
                '"condition_group":{' +
                '"status":1,' +
                '"event":[],' +
                '"defect":["cbDefectError"],' +
                '"action":[],' +
                '"priority":"cbPriorityPolicy",' +
                '"message":"cbMessageErrorGeneric"' +
                '}' +
                '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [
            SELECT
                Last_Point_Time__c,
                Condition_Index__c,
                Urgency_Code__c,
                Defect_Codes__c,
                ML_Message__c,
                Circuit_Breaker_Model__c
            FROM Circuit_Breaker__c
            WHERE Id = :cb.Id
        ];
        System.assertEquals(LAST_POINT_TIMESTAMP, cb.Last_Point_Time__c);
        System.assertEquals(1, cb.Condition_Index__c);
        System.assertEquals('cbPriorityPolicy', cb.Urgency_Code__c);
        System.assertEquals('["cbDefectError"]', cb.Defect_Codes__c);
        System.assertEquals('cbMessageErrorGeneric', cb.ML_Message__c);
        System.assertEquals(CB_MODEL_VALUE, cb.Circuit_Breaker_Model__c);
    }

    @isTest
    static void test_ML_Data_onTransformer() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        Transformer__c t = createTransformer();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Transformer',
            AssetId__c = t.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{' +
                '"timestamp":' +
                LAST_POINT_TIMESTAMP +
                ',' +
                '"condition_group":{' +
                '"status":4.2,' +
                '"event":[],' +
                '"defect":["cbDefectError"],' +
                '"action":["cbActionNone"],' +
                '"priority":"cbPriorityPolicy"' +
                '}' +
                '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        t = [
            SELECT Last_Point_Time__c, Condition_Index__c, Urgency_Code__c, Activities_Codes__c
            FROM Transformer__c
            WHERE Id = :t.Id
        ];
        System.assertEquals(LAST_POINT_TIMESTAMP, t.Last_Point_Time__c);
        System.assertEquals(4.2, t.Condition_Index__c);
        System.assertEquals('cbPriorityPolicy', t.Urgency_Code__c);
        System.assertEquals('["cbActionNone"]', t.Activities_Codes__c);
    }

    @isTest
    static void test_emptyData() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = ''
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
    }

    @isTest
    static void test_emptyDataObject() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
    }

    @isTest
    static void test_unknownAssetCategory() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Unicorns',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{"condition_group":{"status":1}}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
    }

    @isTest
    static void test_missingTimestampDataField() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{"condition_group":{"status":1}}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
    }

    @isTest
    static void test_noMatchWithAnyCircuitBreaker() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = 'xxx@yyy',
            Data_Type__c = 'ML_Data',
            Data__c = '{' +
                '"timestamp":' +
                LAST_POINT_TIMESTAMP +
                ',' +
                '"condition_group":{' +
                '"status":1,' +
                '"event":["cbEventNone"],' +
                '"defect":["cbDefectNone"],' +
                '"action":["cbActionNone"],' +
                '"priority":"cbPriorityPolicy"' +
                '}' +
                '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
    }

    @isTest
    static void test_noMatchWithAnyTransformer() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        Transformer__c t = createTransformer();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Transformer',
            AssetId__c = 'xxx@yyy',
            Data_Type__c = 'ML_Data',
            Data__c = '{' +
                '"timestamp":' +
                LAST_POINT_TIMESTAMP +
                ',' +
                '"condition_group":{' +
                '"status":1,' +
                '"event":["cbEventNone"],' +
                '"defect":["cbDefectNone"],' +
                '"action":["cbActionNone"],' +
                '"priority":"cbPriorityPolicy"' +
                '}' +
                '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        t = [SELECT Condition_Index__c, Activities_Codes__c FROM Transformer__c WHERE Id = :t.Id];
        System.assertEquals(0, t.Condition_Index__c);
    }

    @isTest
    static void test_unknownDataTypeOnCircuitBreaker() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'Strange',
            Data__c = '{"timestamp":' + LAST_POINT_TIMESTAMP + '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
    }

    @isTest
    static void test_unknownDataTypeOnTransformer() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        Transformer__c t = createTransformer();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Transformer',
            AssetId__c = t.Asset_ID__c,
            Data_Type__c = 'Strange',
            Data__c = '{"timestamp":' + LAST_POINT_TIMESTAMP + '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        t = [SELECT Condition_Index__c, Activities_Codes__c FROM Transformer__c WHERE Id = :t.Id];
        System.assertEquals(0, t.Condition_Index__c);
    }

    @isTest
    static void test_ML_Data_missinConditionGroupOnCircuitBreaker() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{"timestamp":' + LAST_POINT_TIMESTAMP + '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
    }

    @isTest
    static void test_ML_Data_missingConditionGroupOnTransformer() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        Transformer__c t = createTransformer();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Transformer',
            AssetId__c = t.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{"timestamp":' + LAST_POINT_TIMESTAMP + '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        t = [SELECT Condition_Index__c, Activities_Codes__c FROM Transformer__c WHERE Id = :t.Id];
        System.assertEquals(0, t.Condition_Index__c);
    }

    @isTest
    static void test_ML_Data_missingStatusOnCircuitBreaker() {
        Test.startTest();

        Circuit_Breaker__c cb = createCircuitBreaker();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'CircuitBreaker',
            AssetId__c = cb.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{' + '"timestamp":' + LAST_POINT_TIMESTAMP + ',' + '"condition_group":{}' + '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        cb = [SELECT Condition_Index__c, Urgency_Code__c, Defect_Codes__c FROM Circuit_Breaker__c WHERE Id = :cb.Id];
        System.assertEquals(0, cb.Condition_Index__c);
        System.assertEquals(null, cb.Urgency_Code__c);
        System.assertEquals(null, cb.Defect_Codes__c);
    }

    @isTest
    static void test_ML_Data_missingStatusOnTransformer() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        Transformer__c t = createTransformer();

        SCI_Asset_Data_Update__e event = new SCI_Asset_Data_Update__e(
            Asset_Category__c = 'Transformer',
            AssetId__c = t.Asset_ID__c,
            Data_Type__c = 'ML_Data',
            Data__c = '{' + '"timestamp":' + LAST_POINT_TIMESTAMP + ',' + '"condition_group":{}' + '}'
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        t = [SELECT Condition_Index__c, Urgency_Code__c, Activities_Codes__c FROM Transformer__c WHERE Id = :t.Id];
        System.assertEquals(0, t.Condition_Index__c);
        System.assertEquals(null, t.Urgency_Code__c);
        System.assertEquals(null, t.Activities_Codes__c);
    }
}