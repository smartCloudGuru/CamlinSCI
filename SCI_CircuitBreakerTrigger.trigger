trigger SCI_CircuitBreakerTrigger on Circuit_Breaker__c(before insert, before update) {
    for (Circuit_Breaker__c cb : Trigger.new) {
        // Sets Circuit Breaker ID, if missing
        if (cb.Circuit_Breaker_ID__c == null || cb.Circuit_Breaker_ID__c.trim().length() == 0) {
            List<Circuit_Breaker__c> breakers = [
                SELECT Asset_ID__c
                FROM Circuit_Breaker__c
                WHERE Circuit_Breaker__c.Company__c = :cb.Company__c
            ];

            integer max = -1;
            for (Circuit_Breaker__c br : breakers) {
                max = Math.max(max, Integer.valueOf(br.Asset_ID__c.split('@')[0].split('-')[1]));
            }

            cb.Circuit_Breaker_ID__c = 'CB-' + String.valueOf(max + 1).leftPad(5, '0');
        }

        // Checks if Circuit Breaker already exists
        if (Trigger.isInsert) {
            List<Circuit_Breaker__c> alreadyExistingCircuitBreakers = [
                SELECT Id
                FROM Circuit_Breaker__c
                WHERE
                    Circuit_Breaker__c.Company__c = :cb.Company__c
                    AND Circuit_Breaker__c.Circuit_Breaker_ID__c = :cb.Circuit_Breaker_ID__c
            ];

            if (alreadyExistingCircuitBreakers != null && alreadyExistingCircuitBreakers.size() != 0) {
                cb.addError(
                    'Cannot create Circuit Breaker record with the same Circuit Breaker ID and Company of another ' +
                    'record.'
                );
            }
        }

        // Aligns Condition Group field value with Condition Index field
        if (cb.Condition_Index__c == 1) {
            cb.Condition_Group__c = '1';
        } else if (cb.Condition_Index__c == 2) {
            cb.Condition_Group__c = '2';
        } else if (cb.Condition_Index__c == 3) {
            cb.Condition_Group__c = '3';
        } else if (cb.Condition_Index__c == 4) {
            cb.Condition_Group__c = '4';
        } else {
            cb.Condition_Group__c = '0';
        }

        // Updates Defects field value
        if (cb.Defect_Codes__c != null && cb.Defect_Codes__c.trim().length() > 0) {
            Object[] defectCodes = (Object[]) JSON.deserializeUntyped(cb.Defect_Codes__c);

            if (defectCodes.size() == 0) {
                cb.Defects__c = 'None';
            } else {
                List<String> defectValues = new List<String>();

                for (Object dc : defectCodes) {
                    switch on (String) dc {
                        when 'cbDefectAuxContact' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectBattCharg' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectBattCirc' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectError' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectSlowMainMech' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectSlowTrip1' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectSlowTrip2' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectSlowTripCoil' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectSuspect' {
                            defectValues.add((String) dc);
                        }
                        when 'cbDefectWrongCoilVoltage' {
                            defectValues.add((String) dc);
                        }
                        when else {
                            defectValues.add('None');
                        }
                    }
                }

                cb.Defects__c = String.join(defectValues, ';').replace(';None', '').replace('None;', '');
            }
        } else {
            cb.Defects__c = 'None';
        }
    }
}