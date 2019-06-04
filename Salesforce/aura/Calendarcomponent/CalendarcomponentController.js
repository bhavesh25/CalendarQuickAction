({
    scriptsLoaded : function(component, event, helper) {        
        helper.getResponse(component);
    },
    doInit : function(component, event, helper) {
        //console.log('component.get:::'+component.get("v.recordId"));
        //component.set('v.task.Contact__c',component.get("v.recordId"));
    },
    getInput : function(component, event, helper) {
        var task = component.get('v.task');
        if(task.End_DateTime__c < task.Start_Time__c){
            component.set('v.errorString','End date can not less than start date.');
        } else if( !task.Title__c ){
            component.set('v.errorString','Please provide title.');
        } else {
            component.set('v.errorString','');
            var action = component.get("c.checkEventOverlap");
            action.setParams({
                'task': task
            })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if(result==true){
                        component.set('v.errorString','success');
                        $("#dialog" ).dialog( 'close' );
                        helper.getResponse(component);
                        component.set('v.errorString','');
                    } else {
                        component.set('v.errorString','This event is overlapping with existing event.');
                    }
                }else {
                    component.set('v.errorString','Error while creating the event. Please try after some time.');
                }
            });
            $A.enqueueAction(action);
        }
	},
    deleteEventMethod : function(component, event, helper) {
        var task = component.get('v.task');
        if(task.Id) {
            var action = component.get("c.deleteEvent");
            action.setParams({
                'task': task
            })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if(result==true){
                        component.set('v.errorString','Success');
                        $("#dialog" ).dialog( 'close' );
                        helper.getResponse(component);
                        component.set('v.errorString','');
                    } else {
                        component.set('v.errorString','Error while deleting the event. Please try after some time.');
                    }
                }else {
                        component.set('v.errorString','Error while deleting the event. Please try after some time.');
                }
            });
            $A.enqueueAction(action);
        }
	}
});