({
    getResponse: function(component) {
        var action1 = component.get("c.getTimeZone");
        action1.setCallback(this, function(response1) {
            var state1 = response1.getState();
            if (state1 === "SUCCESS") {
                var timezone = response1.getReturnValue();
                var action = component.get("c.getTasks");
                
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        console.log("Data: \n" + result);
                        var eventArr = [];
                        result.forEach(function(key) {
                            var starttime = moment.tz(key.Start_Time__c, timezone);
                            var endtime = moment.tz(key.End_DateTime__c, timezone);
                            var color = '';var textColor = '';
                            if(key.Status__c == 'ChangePending'){
                                key.Status__c = 'Rescheduled and Pending';
                            }
                            if(key.Status__c == 'Pending' || key.Status__c == 'Rescheduled and Pending'){
                                color='#F0E68C';
                            } else if(key.Status__c == 'Rejected'){
                                color='#F08080';
                            } else {
                                color='#98FB98';
                            }
                            eventArr.push({
                                'id':key.Id,
                                'start': starttime._d,
                                'end':endtime._d,
                                'title':key.Title__c,
                                'status':key.Status__c,
                                'color':color,
                                'textColor': 'black',
                                'contact': key.Contact__c
                            });
                        });
                        console.log(eventArr);
                        this.loadCalendar(eventArr,component);
                        
                    } else if (state === "INCOMPLETE") {
                    } else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
                });
                $A.enqueueAction(action);
            }
        });
        $A.enqueueAction(action1);
        
        
        
        
    },
    
    loadCalendar :function(data,component){ 
        var m = moment();
        $('#calendar').fullCalendar('destroy');
        $('#calendar').fullCalendar({
            
            dayClick : function(event, jsEvent, view) {
                //set the values and open the modal
                var timezone = component.get('v.timezone');
                debugger;
                console.log(event);
                console.log(event.format() );
                component.set('v.task.Start_Time__c',moment.tz(event._d, timezone).toISOString());
                component.set('v.task.Id','');
                component.set('v.task.Title__c','');
                component.set('v.task.Status__c','Pending');
                component.set('v.errorString','');
                component.set('v.task.End_DateTime__c',moment.tz(event._d, timezone).toISOString());
                component.set('v.task.Contact__c',component.get("v.recordId"));

        		$("#dialog").dialog({
                    title: "Create event",
                    open: function (event, ui) {
                        $(".ui-widget-overlay").css({
                            opacity: .50,
                            filter: "Alpha(Opacity=100)",
                            backgroundColor: "grey"
                        });
                    },
                    modal: true,
                    minHeight :200,
                    height: 600,
                    minWidth:500,
                    width:500
                });
            },
            eventClick: function(info) {
                debugger;
                var timezone = component.get('v.timezone');
                component.set('v.task.Title__c',info.title);
                component.set('v.task.Id',info._id);
                component.set('v.errorString','');
                component.set('v.task.Status__c',info.status);
                component.set('v.task.Start_Time__c',moment.tz(info.start._d, timezone).toISOString());
                component.set('v.task.End_DateTime__c',moment.tz(info.end._d, timezone).toISOString());
                component.set('v.task.Contact__c',info.contact);
            	
                
                $("#dialog").dialog({
                    title: "Edit event",
                    open: function (event, ui) {
                        $(".ui-widget-overlay").css({
                            opacity: .50,
                            filter: "Alpha(Opacity=100)",
                            backgroundColor: "grey"
                        });
                    },
                    modal: true,
                    minHeight :200,
                    height: 600,
                    minWidth:500,
                    width:500  

                });
              },
            header: {
                left: 'prev,next today',
                center: 'title',
                right: 'month,agendaWeek,agendaDay,listWeek'
            },
            defaultDate: m.format(),
            editable: false,
            droppable: false,
            navLinks: true, // can click day/week names to navigate views
            weekNumbers: true,
            weekNumbersWithinDays: true,
            weekNumberCalculation: 'ISO',
            eventLimit: true,
            selectOverlap : false,
            events:data
        });
    },
    
})