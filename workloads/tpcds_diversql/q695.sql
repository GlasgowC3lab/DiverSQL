WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_ticket_number,
        ss_item_sk,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
      AND ss_net_profit > 0
),
cs AS (
    SELECT
        cs_sold_time_sk,
        cs_bill_addr_sk,
        cs_ext_sales_price,
        cs_net_profit
    FROM catalog_sales
    WHERE cs_ext_sales_price > 500
      AND cs_net_profit > 0
),
intersect_tickets AS (
    SELECT ss_ticket_number AS ticket_number FROM ss
    INTERSECT
    SELECT sr_ticket_number FROM store_returns
),
joined AS (
    SELECT
        COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
        COALESCE(ss.ss_store_sk, sr.sr_store_sk) AS store_sk,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        st.s_store_name,
        ca.ca_state,
        td.t_sub_shift,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ss.ss_store_sk, sr.sr_store_sk) ORDER BY ss.ss_ext_sales_price DESC) AS rn_sales,
        RANK() OVER (ORDER BY ss.ss_ext_sales_price DESC) AS rank_global,
        cs.cs_ext_sales_price AS cs_ext_sales_price
    FROM ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN store st
        ON COALESCE(ss.ss_store_sk, sr.sr_store_sk) = st.s_store_sk
    LEFT JOIN customer_address ca
        ON COALESCE(ss.ss_addr_sk, sr.sr_addr_sk) = ca.ca_address_sk
    LEFT JOIN time_dim td
        ON COALESCE(ss.ss_sold_time_sk, sr.sr_return_time_sk) = td.t_time_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
       AND cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE (ss.ss_ticket_number IN (SELECT ticket_number FROM intersect_tickets)
           OR sr.sr_ticket_number IN (SELECT ticket_number FROM intersect_tickets))
      AND td.t_sub_shift = 'morning'
      AND ca.ca_state = 'CA'
)
SELECT
    j.ticket_number,
    j.s_store_name,
    j.ca_state,
    j.t_sub_shift,
    j.ss_ext_sales_price,
    j.sr_return_amt,
    j.cs_ext_sales_price,
    j.rn_sales,
    j.rank_global,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_store_sk = j.store_sk) AS store_total_return_amt
FROM joined j
ORDER BY j.ss_ext_sales_price DESC, j.rank_global
LIMIT 100
