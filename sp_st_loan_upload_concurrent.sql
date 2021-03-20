create or replace procedure sp_st_loan_upload_concurrent
(
 lerrbuff          OUT NOCOPY VARCHAR2,
 lerrcode          OUT NOCOPY VARCHAR2,
 P_month     varchar2
)
as
V_FROM_DATE DATE := TO_DATE('01-'||p_month||'','DD-MON-YYYY');
V_TO_DATE DATE := last_day(TO_DATE('01-'||p_month||'','DD-MON-YYYY'));
v_backup_table     varchar2(1000);
v_number   number:=0;
v_run_id   number:=0;

CURSOR C_MAIN_BANKS IS SELECT DISTINCT BANK_ID, BANK_NAME
FROM XX_LOAN_DETAILS
--WHERE BANK_ID IN
--(6049, 6071, 6056, 6057, 6045)
ORDER BY BANK_NAME ;

CURSOR C_SUB_LOANS(P_IN_BANK_ID IN NUMBER) IS SELECT LOAN_ID FROM XX_LOAN_DETAILS WHERE BANK_ID = P_IN_BANK_ID ORDER BY LOAN_ID;

BEGIN

 select seq_st_no.nextval into v_number from dual;
 fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Enter Month nnd Year parameter value  : ' || p_month);
 fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Loan Start Date                       : ' || V_FROM_DATE);
 fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Loan To Date                          : ' || V_TO_DATE);

 --DBMS_OUTPUT.PUT_LINE('parameter Date :' || p_month);
 --DBMS_OUTPUT.PUT_LINE('from date   :' || V_FROM_DATE);
 --DBMS_OUTPUT.PUT_LINE('to date   :' || V_TO_DATE);

 v_backup_table :='create table ST_LOAN_DETAILS_SUMMARY_X1_'|| v_number ||' as select * from ST_LOAN_DETAILS_SUMMARY_X1';

---xx_lt_loan_data table can truncate in future.


 --DBMS_OUTPUT.PUT_LINE('create table    :' || v_backup_table);
  begin
	
		delete from XX_LT_LOAN_DATA1;
		commit;
	
	   fnd_file.PUT_LINE(fnd_file.OUTPUT,'Start Load Data to xx_lt_loan_data '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
       
	   insert into XX_LT_LOAN_DATA1 select * from WG_LOAN_DETAILS_V where ACCOUNTING_DATE between V_FROM_DATE-30 and V_TO_DATE+30;
	   commit;
	   
       fnd_file.PUT_LINE(fnd_file.OUTPUT,'End Load Data to xx_lt_loan_data '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
 exception when others then
  fnd_file.PUT_LINE(fnd_file.OUTPUT,'Error Load xx_lt_loan_data Table');
 end;
 
 
 

 begin
     execute immediate v_backup_table;
 fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Backup Table Name                     : ST_LOAN_DETAILS_SUMMARY_X1_'||v_number);
 exception
 when others then
     execute immediate 'drop table ST_LOAN_DETAILS_SUMMARY_X1_'|| v_number ;
 execute immediate v_backup_table;
 fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Table Name allready availble and its drop automaticaly create new backup table Name   : ST_LOAN_DETAILS_SUMMARY_X1_'||v_number);
 end;

 begin
delete from ST_LOAN_DETAILS_SUMMARY_X1 where AS_OF_DATE=V_TO_DATE;
--DBMS_OUTPUT.PUT_LINE('Delete record');
 end;

FOR C_MAIN IN C_MAIN_BANKS LOOP

FOR C_SUB IN C_SUB_LOANS(C_MAIN.BANK_ID) LOOP

BEGIN
ST_SP_Loan_Details_X2(null,C_MAIN.BANK_ID, C_SUB.LOAN_ID, V_FROM_DATE, V_TO_DATE,v_run_id ); -- for other months
-----ST_SP_Loan_Details_X1(C_MAIN.BANK_ID, C_SUB.LOAN_ID, V_FROM_DATE, V_TO_DATE ); --for feb-17
--DBMS_OUTPUT.PUT_LINE('Bank Id :  '|| C_MAIN.BANK_ID || ' and  loan id '|| C_SUB.LOAN_ID);
EXCEPTION WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('ERROR:' || SQLERRM);
END;
END LOOP; -- SUB
commit;
END LOOP; --MAIN

END sp_st_loan_upload_concurrent;
/