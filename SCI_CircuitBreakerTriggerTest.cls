@isTest
private class SCI_CircuitBreakerTriggerTest {
    private static Asset_Location__c getLocation() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Location__c location = new Asset_Location__c(Name = 'Location', Company__c = company.Id);
        insert location;

        return location;
    }

    private static Circuit_Breaker__c retrieveCbById(Id id) {
        Circuit_Breaker__c cb = [
            SELECT Circuit_Breaker_ID__c, Condition_Group__c, Defects__c
            FROM Circuit_Breaker__c
            WHERE Id = :id
        ];
        return cb;
    }

    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_without_Circuit_Breaker_ID() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assert(retrievedCb.Circuit_Breaker_ID__c.startsWith('CB-'));
        System.assertEquals('0', retrievedCb.Condition_Group__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_Circuit_Breaker_ID() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Condition_Index__c = 0,
            Circuit_Breaker_ID__c = 'Circuit Breaker ID'
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assertEquals('Circuit Breaker ID', retrievedCb.Circuit_Breaker_ID__c);
        System.assertEquals('0', retrievedCb.Condition_Group__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_Condition_Index() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Condition_Index__c = 1
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assert(retrievedCb.Circuit_Breaker_ID__c.startsWith('CB-'));
        System.assertEquals('1', retrievedCb.Condition_Group__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_empty_Defect_Codes() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Condition_Index__c = 2,
            Defect_Codes__c = ''
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assert(retrievedCb.Circuit_Breaker_ID__c.startsWith('CB-'));
        System.assertEquals('2', retrievedCb.Condition_Group__c);
        System.assertEquals('None', retrievedCb.Defects__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_dummy_Defect_Codes() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Condition_Index__c = 3,
            Defect_Codes__c = '[]'
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assert(retrievedCb.Circuit_Breaker_ID__c.startsWith('CB-'));
        System.assertEquals('3', retrievedCb.Condition_Group__c);
        System.assertEquals('None', retrievedCb.Defects__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_single_value_Defect_Codes() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Condition_Index__c = 4,
            Defect_Codes__c = '["cbDefectAuxContact"]'
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assert(retrievedCb.Circuit_Breaker_ID__c.startsWith('CB-'));
        System.assertEquals('4', retrievedCb.Condition_Group__c);
        System.assertEquals('cbDefectAuxContact', retrievedCb.Defects__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_multiple_values_Defect_Codes() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Defect_Codes__c = '["cbDefectBattCharg","cbDefectBattCirc","cbDefectSlowMainMech","cbDefectSlowTrip1","cbDefectSlowTrip2","cbDefectSlowTripCoil","cbDefectSuspect","cbDefectWrongCoilVoltage"]'
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assert(retrievedCb.Circuit_Breaker_ID__c.startsWith('CB-'));
        System.assertEquals('0', retrievedCb.Condition_Group__c);
        System.assertEquals(
            'cbDefectBattCharg;cbDefectBattCirc;cbDefectWrongCoilVoltage;cbDefectSlowTrip1;cbDefectSlowTrip2;cbDefectSuspect;cbDefectSlowMainMech;cbDefectSlowTripCoil',
            retrievedCb.Defects__c
        );

        Test.stopTest();
    }

    @isTest
    static void test_with_multiple_values_with_none_Defect_Codes() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Defect_Codes__c = '["cbDefectNone","cbDefectBattCharg","cbDefectNone"]'
        );
        insert cb;

        Circuit_Breaker__c retrievedCb = retrieveCbById(cb.Id);

        System.assert(retrievedCb.Circuit_Breaker_ID__c != null);
        System.assert(retrievedCb.Circuit_Breaker_ID__c.startsWith('CB-'));
        System.assertEquals('0', retrievedCb.Condition_Group__c);
        System.assertEquals('cbDefectBattCharg', retrievedCb.Defects__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_already_existing_Circuit_Breaker_ID() {
        Test.startTest();

        Asset_Location__c location = getLocation();
        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Circuit_Breaker_ID__c = 'Circuit Breaker ID'
        );
        insert cb;

        Circuit_Breaker__c newCb = new Circuit_Breaker__c(
            Name = 'New Circuit Breaker',
            Company__c = location.Company__c,
            Location__c = location.Id,
            Circuit_Breaker_ID__c = 'Circuit Breaker ID'
        );

        boolean exceptionTriggered = false;

        try {
            Database.insert(newCb);
        } catch (DmlException e) {
            exceptionTriggered = true;
        }

        System.assert(exceptionTriggered);

        Test.stopTest();
    }
}