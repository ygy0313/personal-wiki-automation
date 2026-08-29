# Personal Wiki Automation System

 Obsidian + Git + AWS EC2 + Quartz + Nginx 

## 
- **** Obsidian Web Clipper  `00-Inbox`
- ****Mac  `00-Inbox`  Git 
- ****AWS EC2  Push  Quartz 
- **** Nginx 
- ****

## 

```text
[ Mac]                    []              [AWS EC2]
                   
 Obsidian                                      post-receive Hook    
   Web Clipper                               rsync content    
   00-Inbox/             Git Push     deploy.sh        
                                                  plugin restore
 auto_clipper.sh                                   quartz build  
  (fswatch)                                      verify index  
                         rsync  Nginx 
                                                         reload nginx  
                                                                        
                                                    https://<YOUR_DOMAIN>
                                                   