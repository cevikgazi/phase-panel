#!/usr/bin/python
#coding: utf-8
#-----------------------------
# FTP'YE phase Linux paneli web sitesi yedekleme aracı
#-----------------------------

import sys,os
reload(sys)
sys.setdefaultencoding('utf-8')
os.chdir('/www/server/panel')
sys.path.append("class/")
import public,db,time

class backupFtp:
    
    def backupSite(self,name,count):
        sql = db.Sql()
        path = sql.table('sites').where('name=?',(name,)).getField('path')
        startTime = time.time()
        if not path:
            endDate = time.strftime('%Y/%m/%d %X',time.localtime())
            log = "["+name+"] web sitesi mevcut değil!"
            print ("★["+endDate+"] "+log)
            print ("----------------------------------------------------------------------------")
            return
        
        backup_path = sql.table('config').where("id=?",(1,)).getField('backup_path') + '/site'
        if not os.path.exists(backup_path): public.ExecShell("mkdir -p " + backup_path)
        
        filename= backup_path + "/Web_" + name + "_" + time.strftime('%Y%m%d_%H%M%S',time.localtime()) + '.tar.gz'
        public.ExecShell("cd " + os.path.dirname(path) + " && tar zcvf '" + filename + "' '" + os.path.basename(path) + "' > /dev/null")
        
        endDate = time.strftime('%Y/%m/%d %X',time.localtime())
        
        if not os.path.exists(filename):
            log = "Site ["+name+"] yedeklemesi başarısız oldu!"
            print ("★["+endDate+"] "+log)
            print ("----------------------------------------------------------------------------")
            return
        
        #FTP'ye yükle
        self.updateFtp(filename)
        
        outTime = time.time() - startTime
        pid = sql.table('sites').where('name=?',(name,)).getField('id')
        sql.table('backup').add('type,name,pid,filename,addtime,size',('0',os.path.basename(filename),pid,'ftp',endDate,os.path.getsize(filename)))
        log = "["+name+"] web sitesi başarıyla FTP'ye yedeklendi ve ["+str(round(outTime,2))+"] saniye sürüyor"
        public.WriteLog('Zamanlanmış Görevler',log)
        print ("★["+endDate+"] " + log)
        print ("|---En son ["+count+"] yedeğini saklayın")
        print ("|---dosya adı:"+filename)
        
        os.system('rm -f ' + filename)
        #Gereksiz yedekleri temizleyin    
        backups = sql.table('backup').where('type=? and pid=?',('0',pid)).field('id,name,filename').select()
        
        num = len(backups) - int(count)
        if  num > 0:
            for backup in backups:
                if os.path.exists(backup['filename']):
                    public.ExecShell("rm -f " + backup['filename'])
                self.deleteFtp(backup['name'])
                sql.table('backup').where('id=?',(backup['id'],)).delete()
                num -= 1
                print ("|---Süresi dolan yedekleme dosyaları temizlendi：" + backup['name'])
                if num < 1: break
    
    def backupDatabase(self,name,count):
        sql = db.Sql()
        path = sql.table('databases').where('name=?',(name,)).getField('path')
        startTime = time.time()
        if not path:
            endDate = time.strftime('%Y/%m/%d %X',time.localtime())
            log = "["+name+"] veritabanı mevcut değil!"
            print ("★["+endDate+"] "+log)
            print ("----------------------------------------------------------------------------")
            return
        
        backup_path = sql.table('config').where("id=?",(1,)).getField('backup_path') + '/database'
        if not os.path.exists(backup_path): public.ExecShell("mkdir -p " + backup_path)
        
        filename = backup_path + "/Db_" + name + "_" + time.strftime('%Y%m%d_%H%M%S',time.localtime())+".sql.gz"
        
        import re
        mysql_root = sql.table('config').where("id=?",(1,)).getField('mysql_root')
        mycnf = public.readFile('/etc/my.cnf')
        rep = "\[mysqldump\]\nuser=root"
        sea = '[mysqldump]\n'
        subStr = sea + "user=root\npassword=" + mysql_root+"\n"
        mycnf = mycnf.replace(sea,subStr)
        if len(mycnf) > 100:
            public.writeFile('/etc/my.cnf',mycnf)
        
        public.ExecShell("/www/server/mysql/bin/mysqldump --opt --default-character-set=utf8 " + name + " | gzip > " + filename)
        
        if not os.path.exists(filename):
            endDate = time.strftime('%Y/%m/%d %X',time.localtime())
            log = "Veritabanı ["+name+"] yedeklemesi başarısız oldu!"
            print ("★["+endDate+"] "+log)
            print ("----------------------------------------------------------------------------")
            return
        
        mycnf = public.readFile('/etc/my.cnf')
        mycnf = mycnf.replace(subStr,sea)
        if len(mycnf) > 100:
            public.writeFile('/etc/my.cnf',mycnf)
        
        
        #FTP'ye yükle
        self.updateFtp(filename)
        
        endDate = time.strftime('%Y/%m/%d %X',time.localtime())
        outTime = time.time() - startTime
        pid = sql.table('databases').where('name=?',(name,)).getField('id')
        
        sql.table('backup').add('type,name,pid,filename,addtime,size',(1,os.path.basename(filename),pid,'ftp',endDate,os.path.getsize(filename)))
        log = "["+name+"] veritabanı başarıyla yedeklendi ve ["+str(round(outTime,2))+"] saniye sürdü"
        public.WriteLog('Zamanlanmış Görevler',log)
        print ("★["+endDate+"] " + log)
        print ("|---En son ["+count+"] yedeğini saklayın")
        print ("|---dosya adı:"+filename)
        
        os.system('rm -f ' + filename)
        #Gereksiz yedekleri temizleyin     
        backups = sql.table('backup').where('type=? and pid=?',('1',pid)).field('id,name,filename').select()
        
        num = len(backups) - int(count)
        if  num > 0:
            for backup in backups:
                if os.path.exists(backup['filename']):
                    public.ExecShell("rm -f " + backup['filename'])
                self.deleteFtp(backup['name'])
                sql.table('backup').where('id=?',(backup['id'],)).delete()
                num -= 1
                print ("|---Süresi dolan yedekleme dosyaları temizlendi：" + backup['name'])
                if num < 1: break
    
    #FTP'ye bağlan
    def connentFtp(self):
        try:
            from ftplib import FTP
            ftpAs = public.readFile('data/ftpAs.conf')
            tmp = ftpAs.split('|')
            if tmp[0].find(':') == -1: tmp[0] += ':21'
            host = tmp[0].split(':')
            if host[1] == '': host[1] = '21'
            ftp=FTP() 
            ftp.set_debuglevel(0)
            ftp.connect(host[0],host[1])
            ftp.login(tmp[1],tmp[2])
            ftp.cwd(tmp[3].replace('//','/'))
            return ftp
        except:
            print ('FTP\'ye bağlanılamadı, lütfen FTP oturum açma bilgilerinin doğru ayarlanıp ayarlanmadığını kontrol edin!')
            return {'status':False,'msg':'Bağlantı hatası!'}
    
    #dosyaları yükle
    def updateFtp(self,filename):
        #try:
        ftp = self.connentFtp()
        bufsize = 1024
        file_handler = open(filename,'rb')
        ftp.storbinary('STOR %s' % os.path.basename(filename),file_handler,bufsize)
        file_handler.close() 
        ftp.quit()
        #except:
            #return {'status':False,'msg':'Bağlantı hatası!'}
    
    #FTP'den dosya silme
    def deleteFtp(self,filename):
        try:
            ftp = self.connentFtp()
            ftp.delete(filename)
            return True
        except:
            return {'status':False,'msg':'Bağlantı hatası!'}
    
    #Listeyi al
    def getList(self):
        try:
            ftp = self.connentFtp()
            result =  ftp.nlst()
            data = []
            for dt in result:
                if dt == '.' or dt == '..': continue
                sfind = public.M('backup').where('name=?',(dt,)).field('size,addtime').find()
                tmp = {}
                tmp['mimeType'] = 'application/test'
                tmp['fsize'] = sfind['size']
                tmp['hash'] = ''
                tmp['key'] = dt
                tmp['putTime'] = int(time.mktime(time.strptime(sfind['addtime'],'%Y/%m/%d %H:%M:%S')))
                data.append(tmp)
            if len(data) == 0:
                return [{"mimeType": "application/test", "fsize": 0, "hash": "", "key": "Dosya yok", "putTime": 14845314157209192}]
            return data
        except:
            return {'status':False,'msg':'Bağlantı hatası!'}
    #dosya adresini al
    def getFile(self,filename):
        ftpAs = public.readFile('data/ftpAs.conf')
        tmp = ftpAs.split('|')
        if tmp[0].find(':') == -1: tmp[0] += ':21'
        host = tmp[0].split(':')
        if host[1] == '': host[1] = '21'
        return 'ftp://'+ tmp[1]+ ':'+ tmp[2] + '@' +  host[0] + ':' + host[1] + tmp[3] + '/' + filename


if __name__ == "__main__":
    import json
    data = None
    backup = backupFtp()
    type = sys.argv[1]
    if type == 'site':
        data = backup.backupSite(sys.argv[2], sys.argv[3])
        exit()
    elif type == 'database':
        data = backup.backupDatabase(sys.argv[2], sys.argv[3])
        exit()
    elif type == 'list':
        data = backup.getList()
    elif type == 'download':
        data = backup.getFile(sys.argv[2])
    
    print (json.dumps(data))
    