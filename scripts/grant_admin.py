#!/usr/bin/env python3
"""Grant admin to one confirmed existing Supabase account. Does not create accounts.
Run only for an account you explicitly authorize. Refresh/sign in again afterward.
"""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from run_backend import load_environment


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--email',required=True,help='Existing, confirmed account to authorize')
    args=parser.parse_args()
    email=args.email.strip()
    if '@' not in email or len(email)>254:
        raise SystemExit('Invalid email.')
    env=load_environment()
    java_home=env.get('JAVA_HOME') or str(Path.home()/'.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home')
    jars=sorted((Path.home()/'.m2/repository/org/postgresql/postgresql').glob('*/*.jar'))
    if not jars:raise SystemExit('Build backend to download the PostgreSQL driver first.')
    env['ADMIN_TARGET_EMAIL']=email
    source='''import java.sql.*;
class GrantAdmin { public static void main(String[] args)throws Exception{
 DriverManager.setLoginTimeout(20);
 try(var c=DriverManager.getConnection(System.getenv("SPRING_DATASOURCE_URL"),System.getenv("SPRING_DATASOURCE_USERNAME"),System.getenv("SPRING_DATASOURCE_PASSWORD"))){
 c.setAutoCommit(false);
 try{
 java.util.UUID id;
 try(var s=c.prepareStatement("select id from auth.users where lower(email)=lower(?) and email_confirmed_at is not null for update")){
 s.setString(1,System.getenv("ADMIN_TARGET_EMAIL"));try(var r=s.executeQuery()){
 if(!r.next())throw new IllegalStateException("Expected one confirmed account");id=r.getObject(1,java.util.UUID.class);if(r.next())throw new IllegalStateException("Ambiguous account");}}
 try(var s=c.prepareStatement("update auth.users set raw_app_meta_data=jsonb_set(coalesce(raw_app_meta_data,'{}'::jsonb),'{role}',to_jsonb(cast(? as text)),true),updated_at=now() where id=?")){
 s.setString(1,"admin");s.setObject(2,id);if(s.executeUpdate()!=1)throw new IllegalStateException("Unexpected update count");}
 c.commit();System.out.println("Admin role granted to the single confirmed target account. Sign in again to refresh claims.");
 }catch(Exception e){c.rollback();throw e;}
 }
}}
'''
    with tempfile.TemporaryDirectory() as tmp:
        path=Path(tmp)/'GrantAdmin.java';path.write_text(source)
        result=subprocess.run([str(Path(java_home)/'bin/java'),'--class-path',str(jars[-1]),str(path)],env=env,capture_output=True,text=True,timeout=60)
        if result.returncode:
            raise SystemExit('Grant failed. No role change committed; verify the account is registered/confirmed and the database role has permission. Details hidden.')
        print(result.stdout.strip())


if __name__=='__main__':main()
