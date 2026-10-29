trigger CaseTrigger on Case (before insert, before update) {
    CaseTriggerHandler.beforeSave(Trigger.new);
}
