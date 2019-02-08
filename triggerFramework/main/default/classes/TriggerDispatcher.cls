public class TriggerDispatcher {

    public static void handle(Schema.sObjectType soType)
    {
        List<TriggerConfig__mdt> handlerConfigs = [
            SELECT DeveloperName, Class_Name__c
            FROM TriggerConfig__mdt
            WHERE Trigger_sObject__c =: soType.getDescribe().getName() AND
                Active__c = TRUE AND Unit_Test_Only__c =: Test.isRunningTest()
            ORDER BY Order_of_Execution__c ASC
        ];

        if(handlerConfigs.isEmpty()) {
            system.debug('Trigger Framework: No active triggesr for ' + soType);
            return;
        }

        List<ITriggerHandler> handlers = new List<ITriggerHandler>();
        Map<TriggerFrameworkAction, Boolean> initActions = new Map<TriggerFrameworkAction, Boolean>();
        Map<TriggerFrameworkAction, Boolean> doActions = new Map<TriggerFrameworkAction, Boolean>();

        for(TriggerConfig__mdt conf : handlerConfigs) {
            Type t = Type.forName(conf.Class_Name__c);
            if(t == null) {
                throw new TriggerFrameworkException('Trigger Framework: Invalid Config! Cannot find class ['+conf.Class_Name__c+']');
            }
            ITriggerHandler handler = (ITriggerHandler)t.newInstance();

            for(TriggerFrameworkAction action : TriggerFrameworkAction.values()) {
                if(handler.shouldDoInit(action)) {
                    initActions.put(action, true);
                }
                else if(!initActions.containsKey(action)){
                    initActions.put(action, false);
                }

                if(handler.shouldDoAction(action)) {
                    doActions.put(action, true);
                }
                else if(!doActions.containsKey(action)){
                    doActions.put(action, false);
                }
            }

            handlers.add(handler);
        }

        if(Trigger.isInsert) {
            for(ITriggerHandler handler : handlers) {
                if(Trigger.isBefore) {
                    if(initActions.get(TriggerFrameworkAction.BEFORE_INSERT)) {
                        for(sObject o : Trigger.new) {
                            handler.beforeInsertInit(o);
                        }
                    }
                    if(initActions.get(TriggerFrameworkAction.BEFORE_INSERT_BULK)) {
                        handler.beforeInsertInitBulk(Trigger.new);
                    }
                    if(doActions.get(TriggerFrameworkAction.BEFORE_INSERT)) {
                        for(sObject o : Trigger.new) {
                            handler.onBeforeInsert(o);
                        }
                    }
                    if(doActions.get(TriggerFrameworkAction.BEFORE_INSERT_BULK)) {
                        handler.onBeforeInsertBulk(Trigger.new);
                    }   
                    handler.beforeInsertFinally();               
                }
                if(Trigger.isAfter) {
                    if(initActions.get(TriggerFrameworkAction.AFTER_INSERT)) {
                        for(sObject o : Trigger.new) {
                            handler.afterInsertInit(o);
                        }
                    }
                    if(initActions.get(TriggerFrameworkAction.AFTER_INSERT_BULK)) {
                        handler.afterInsertInitBulk(Trigger.newMap);
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_INSERT)) {
                        for(sObject o : Trigger.new) {
                            handler.onAfterInsert(o);
                        }
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_INSERT_BULK)) {
                        handler.onAfterInsertBulk(Trigger.newMap);
                    }
                    handler.afterInsertFinally();
                }
            }
        }

        if(Trigger.isUpdate) {
            for(ITriggerHandler handler : handlers) {
                if(Trigger.isBefore) {
                    if(initActions.get(TriggerFrameworkAction.BEFORE_UPDATE)) {
                        for(sObject o : Trigger.new) {
                            handler.beforeUpdateInit(Trigger.oldMap.get(o.Id), o);
                        }
                    }
                    if(initActions.get(TriggerFrameworkAction.BEFORE_UPDATE_BULK)) {
                        handler.beforeUpdateInitBulk(Trigger.oldMap, Trigger.newMap);
                    }
                    if(doActions.get(TriggerFrameworkAction.BEFORE_UPDATE)) {
                        for(sObject o : Trigger.new) {
                            handler.onBeforeUpdate(Trigger.oldMap.get(o.Id), o);
                        }
                    }
                    if(doActions.get(TriggerFrameworkAction.BEFORE_UPDATE_BULK)) {
                        handler.onBeforeUpdateBulk(Trigger.oldMap, Trigger.newMap);
                    }   
                    handler.beforeUpdateFinally();               
                }
                if(Trigger.isAfter) {
                    if(initActions.get(TriggerFrameworkAction.AFTER_UPDATE)) {
                        for(sObject o : Trigger.new) {
                            handler.afterUpdateInit(Trigger.oldMap.get(o.Id), o);
                        }
                    }
                    if(initActions.get(TriggerFrameworkAction.AFTER_UPDATE_BULK)) {
                        handler.afterUpdateInitBulk(Trigger.oldMap, Trigger.newMap);
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_UPDATE)) {
                        for(sObject o : Trigger.new) {
                            handler.onAfterUpdate(Trigger.oldMap.get(o.Id), o);
                        }
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_UPDATE_BULK)) {
                        handler.onAfterUpdateBulk(Trigger.oldMap, Trigger.newMap);
                    }
                    handler.afterUpdateFinally();
                }
            }
        }

        if(Trigger.isDelete) {
            for(ITriggerHandler handler : handlers) {
                if(Trigger.isBefore) {
                    if(initActions.get(TriggerFrameworkAction.BEFORE_DELETE)) {
                        for(sObject o : Trigger.old) {
                            handler.beforeDeleteInit(o);
                        }
                    }
                    if(initActions.get(TriggerFrameworkAction.BEFORE_DELETE_BULK)) {
                        handler.beforeDeleteInitBulk(Trigger.oldMap);
                    }
                    if(doActions.get(TriggerFrameworkAction.BEFORE_DELETE)) {
                        for(sObject o : Trigger.old) {
                            handler.onBeforeDelete(o);
                        }
                    }
                    if(doActions.get(TriggerFrameworkAction.BEFORE_DELETE_BULK)) {
                        handler.onBeforeDeleteBulk(Trigger.oldMap);
                    }   
                    handler.beforeDeleteFinally();               
                }
                if(Trigger.isAfter) {
                    if(initActions.get(TriggerFrameworkAction.AFTER_DELETE)) {
                        for(sObject o : Trigger.old) {
                            handler.afterDeleteInit(o);
                        }
                    }
                    if(initActions.get(TriggerFrameworkAction.AFTER_DELETE_BULK)) {
                        handler.afterDeleteInitBulk(Trigger.oldMap);
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_DELETE)) {
                        for(sObject o : Trigger.old) {
                            handler.onAfterDelete(o);
                        }
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_DELETE_BULK)) {
                        handler.onAfterDeleteBulk(Trigger.oldMap);
                    }
                    handler.afterDeleteFinally();
                }
            }
        }

        if(Trigger.isUndelete) {
            for(ITriggerHandler handler : handlers) {
                if(Trigger.isAfter) {
                    if(initActions.get(TriggerFrameworkAction.AFTER_UNDELETE)) {
                        for(sObject o : Trigger.new) {
                            handler.afterUndeleteInit(o);
                        }
                    }
                    if(initActions.get(TriggerFrameworkAction.AFTER_UNDELETE_BULK)) {
                        handler.afterUndeleteInitBulk(Trigger.newMap);
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_UNDELETE)) {
                        for(sObject o : Trigger.new) {
                            handler.onAfterUndelete(o);
                        }
                    }
                    if(doActions.get(TriggerFrameworkAction.AFTER_UNDELETE_BULK)) {
                        handler.onAfterUndeleteBulk(Trigger.newMap);
                    }
                    handler.afterUndeleteFinally();
                }
            }
        }
    }

}