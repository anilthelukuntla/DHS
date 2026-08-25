global class ScheduleSetPasswordForCD implements Schedulable {
    global void execute(SchedulableContext ctx) {
        SetPasswordForCD.setPassword();
    }
}