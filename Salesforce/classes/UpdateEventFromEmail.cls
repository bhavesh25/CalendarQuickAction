global class UpdateEventFromEmail implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,
    Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		String body =email.plainTextBody;
		String subToCompare = 'Meeting Invite:';
		if(email.subject.indexOf(subToCompare) != -1)
		{
            boolean isAccepted;
            body = body.remove('yes or no');
            if(body.indexOfIgnoreCase('yes') != -1){
                isAccepted = true;
            } else if(body.indexOfIgnoreCase('no')  != -1){
                isAccepted = false;
            }
            if( isAccepted != null ){
                String inviteCode = email.subject.subString(email.subject.lastIndexOf (':')+1);
                System.debug('inviteCode:=='+inviteCode);
                if(!String.isEmpty(inviteCode)){
                    Task__c taskToUpdate= new Task__c();
                    for(Task__c task: [Select Id, Status__c FROM Task__C where Name=:inviteCode LIMIT 1]){
                        taskToUpdate = task;
                    }
                    System.debug('taskToUpdate:=='+taskToUpdate);
                    if(taskToUpdate.Id != null){
                        if(isAccepted)
                        	taskToUpdate.Status__c = 'Accepted';
                        else 
                            taskToUpdate.Status__c = 'Rejected';
                        update taskToUpdate;
                    }
                    
                }
            }
			
            
		}

		result.success = true;
        return result;
    }

    /*static testMethod void testCreateContactFrmEmail() {
    	Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();

        //email.subject = 'Create Contact';
        //email.plainTextBody = 'FromEmail';
        //env.fromAddress = 'ilovenagpur@gmail.com';

        //CreateContactFrmEmail creatC = new CreateContactFrmEmail();
        creatC.handleInboundEmail(email, env );
    }*/
}
