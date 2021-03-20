create or replace procedure ST_SP_Loan_Details_X2(P_ORG_ID IN NUMBER ,P_BANK_ID IN NUMBER, P_LOAN_ID IN NUMBER, P_FROM_DATE IN DATE, P_TO_DATE IN DATE)
AS 

BEGIN

 COMMIT; --to clear off GT table values
 
 
 


ST_SP_LOAN_DETAILS_SUMMARY_X1(P_ORG_ID,P_BANK_ID, P_LOAN_ID, P_FROM_DATE, P_TO_DATE);

INSERT INTO ST_LOAN_DETAILS_SUMMARY_X1
(BANK_ID, BANK_NAME, LOAN_ID, LOAN_NUMBER, OPENING_DATE, AS_OF_DATE, EFFECTIVE_START_DATE, EFFECTIVE_END_DATE, OB_PRINCIPLE, OB_INTEREST, OB_TOTAL,
ADD_PRINCIPLE, ADD_INTEREST, ADD_TOTAL, ADJST_PRINCIPLE, ADJST_INTEREST, ADJST_TOTAL, 
NETT_PAY_PRINCIPLE, NETT_PAY_INTEREST, NETT_PAY_TOTAL , PAYMENT_DATE)

SELECT
t2.BANK_ID, 
t1.BANK_NAME, t1.LOAN_ID, t1.LOAN_NUMBER, t1.OPENING_DATE, P_TO_DATE, t1.EFFECTIVE_START_DATE, t1.EFFECTIVE_END_DATE,
t1.OB_PRINCIPLE, t1.OB_INTEREST, t1.OB_TOTAL,
t1.ADD_PRINCIPLE, t1.ADD_INTEREST, t1.ADD_TOTAL,
t1.ADJST_PRINCIPLE, t1.ADJST_INTEREST, t1.ADJST_TOTAL,
t1.NETT_PAY_PRINCIPLE, 
t1.NETT_PAY_INTEREST, 
t1.NETT_PAY_TOTAL
, PAYMENT_DATE
FROM
ST_LOAN_DETAILS_X1_GT t1, 
xx_loan_details t2
where t1.loan_id = t2.loan_id
and t2.bank_name = t2.bank_name;

EXCEPTION WHEN OTHERS then DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);

END;
/