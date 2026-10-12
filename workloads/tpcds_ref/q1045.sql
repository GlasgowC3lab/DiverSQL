select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 128 and 128+10 
             or ss_coupon_amt between 5599 and 5599+1000
             or ss_wholesale_cost between 45 and 45+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 124 and 124+10
          or ss_coupon_amt between 8104 and 8104+1000
          or ss_wholesale_cost between 8 and 8+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 154 and 154+10
          or ss_coupon_amt between 15574 and 15574+1000
          or ss_wholesale_cost between 13 and 13+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 86 and 86+10
          or ss_coupon_amt between 8801 and 8801+1000
          or ss_wholesale_cost between 9 and 9+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 6 and 6+10
          or ss_coupon_amt between 6964 and 6964+1000
          or ss_wholesale_cost between 72 and 72+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 172 and 172+10
          or ss_coupon_amt between 11674 and 11674+1000
          or ss_wholesale_cost between 2 and 2+20)) B6
limit 100
