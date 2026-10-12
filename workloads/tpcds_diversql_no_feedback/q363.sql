WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        MIN(cs.cs_order_number) AS exemplar_order_number,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cs.cs_item_sk, cs.cs_bill_customer_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cust_bill.c_first_name,
    cust_bill.c_last_name,
    s.s_store_name,
    ss.ss_quantity,
    sales_agg.total_net_paid,
    sales_agg.sales_cnt,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    income.ib_upper_bound
FROM sales_agg
JOIN item i
    ON sales_agg.cs_item_sk = i.i_item_sk
JOIN customer cust_bill
    ON sales_agg.cs_bill_customer_sk = cust_bill.c_customer_sk
FULL OUTER JOIN catalog_returns cr
    ON cr.cr_order_number = sales_agg.exemplar_order_number
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band income
    ON hd.hd_income_band_sk = income.ib_income_band_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_refund
    ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = sales_agg.exemplar_order_number
      AND cr2.cr_return_amount > 0
)
AND s.s_number_employees > (SELECT AVG(c_customer_sk) FROM customer)
ORDER BY i.i_item_id
LIMIT 100
