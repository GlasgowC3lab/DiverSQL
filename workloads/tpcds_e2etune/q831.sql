WITH department_profit AS (
    SELECT
        cp.cp_department,
        p.p_channel_tv,
        ca_bill.ca_country,
        cd_bill.cd_gender,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2450900
      AND cp.cp_end_date_sk > cp.cp_start_date_sk
      AND p.p_discount_active = 'Y'
      AND p.p_channel_tv = 'Y'
      AND ca_bill.ca_country = 'United States'
      AND cd_bill.cd_gender = 'M'
    GROUP BY cp.cp_department, p.p_channel_tv, ca_bill.ca_country, cd_bill.cd_gender
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    dp.*,
    RANK() OVER (PARTITION BY dp.ca_country ORDER BY dp.total_profit DESC) AS profit_rank
FROM department_profit dp
ORDER BY dp.total_profit DESC
LIMIT 100
