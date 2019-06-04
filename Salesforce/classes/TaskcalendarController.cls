//Controller class for Calendarcomponent Component.
public class TaskcalendarController {
    
    //return all the events of logged in user.
    @AuraEnabled
    public static List<Task__c> getTasks(){
        List<Task__c> result = new List<Task__c>([Select Id, Start_Time__c ,End_DateTime__c,Name, TItle__c, Status__c,Contact__c 
                                                  from Task__c where Status__c != 'Cancelled'
                                                  	And User__c =:USerInfo.getUserId() ]);
        return result ; 
    } 
    
    //get time zone of user to convert into local time zone from utc.
    @AuraEnabled
    public static String getTimeZone( ){
        User u = [Select TimeZoneSidKey from User where id =: USerInfo.getUserId()];
        return u.TimeZoneSidKey;
    }
    
    //used to delete event from UI
    @AuraEnabled
    public static Boolean deleteEvent( Task__c task){
        try{
            if(String.isNotBlank(task.Id)){
                update new Task__C(Id = task.Id, Status__c = 'Cancelled');
                sendEmail(task.Id);
                return true;
            } else {
                return false;
            }
        } catch(exception e){
            return false;
        }
    }
    
    //check if there is any event overlap, if not upsert the record and send email.
    @AuraEnabled
    public static boolean checkEventOverlap(Task__c task ){
        try{
            Task__c ts = new Task__c();
            Boolean isOverlape = false;
            String userId = UserInfo.getUserId();
            system.debug('task::::'+task);
            for(Task__c existingTask : [Select Id, Start_Time__c ,End_DateTime__c,Name, TItle__c, Status__c from Task__c 
                          where User__c = :userId
                            AND ( Status__c != 'Pending' OR Status__C = 'ChangePending' OR Status__C = 'Accepted') ]){
                system.debug('existingTask::::'+existingTask);
                if( (task.Start_Time__c > existingTask.Start_Time__c && task.Start_Time__c < existingTask.End_DateTime__c)
                  || (task.End_DateTime__c > existingTask.Start_Time__c && task.End_DateTime__c < existingTask.End_DateTime__c)
                  || (task.Start_Time__c < existingTask.Start_Time__c && task.End_DateTime__c > existingTask.End_DateTime__c)
                  || (task.Start_Time__c == existingTask.Start_Time__c && task.End_DateTime__c == existingTask.End_DateTime__c)){
                      if( task.Id != null && existingTask.id != task.id){
                            isOverlape = true;
                            break;
                      }
                }
            }
                    
            if(isOverlape){
                return false;
            } else {
                task.User__c = userId;
                if( String.isBlank(task.id))
                    task.id = ts.id;
                else 
                    task.Status__c = 'ChangePending';
                upsert task;
                sendEmail(task.Id);
                return true;
            }
        }Catch(exception e){
            return false;
        }
        
        
    }
    
    
    //send email method.
    public static void sendEmail(Id taskId){
        Task__c task = new Task__c();
        //again quering the task rec, as task is updated and now I want to get new data,
        // if anything is being udpated from trigger
        for(Task__c taskrec : [Select Id, Start_Time__c ,End_DateTime__c,Name, 
                             TItle__c, Status__c , User__r.Name, Contact__r.LastName, Contact__r.Email
                             From Task__c 
                      		where Id = :taskid LIMIT 1]){
            task = taskrec;
        }
        if(task.Contact__r.Email != null){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { task.Contact__r.Email };
            message.optOutPolicy = 'FILTER';
            message.subject = 'Meeting Invite:'+ (''+task.Title__c).toUpperCase()+' and EventCode:'+task.Name;
            String setHtmlBody  = '<p>Hi '+task.Contact__r.LastName+'</p>';
            if(task.Status__c == 'Pending')
                setHtmlBody  += '</br><p>You have been invited to the following event.</p>';
            else if(task.Status__c == 'ChangePending')
                setHtmlBody  += '</br><p>An event has been updated with the following details.</p>';
            else if(task.Status__c == 'Cancelled')
                setHtmlBody  += '</br><p>An event has been Cancelled with the following details.</p>';
            setHtmlBody  += '<p>Event: '+(''+task.Title__c).toUpperCase()+'</p>';
            setHtmlBody  += '<p>By: <b>'+(''+task.User__r.Name).toUpperCase()+'</b></p>';
            setHtmlBody  += '<p>Start: <b>'+task.Start_time__c.format()+'</b></p>';
            setHtmlBody  += '<p>End: <b>'+task.End_DateTime__c.format()+'</b></p>';
            //setHtmlBody  += '<p>End Time:'+task.End_DateTime__c.time().format()+'</p>';
            setHtmlBody  += '</br><p>To confirm your availablity just reply with yes or no.</p>';
            setHtmlBody  += '</br><p>Thank you.</p>';
            message.setReplyTo(Label.Email_Service_Id );
            message.setHtmlBody(setHtmlBody);
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
        
        
        
        
        
    }
}