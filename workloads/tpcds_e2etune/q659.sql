WITH sales_filtered AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_net_paid
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2451500
)
SELECT
    s.s_store_name,
    s.s_state,
    SUM(sf.ss_net_profit) AS total_net_profit,
    AVG(sf.ss_ext_discount_amt) AS avg_discount_amount,
    SUM(sf.ss_quantity) AS total_quantity_sold,
    COUNT(*) AS transaction_count,
    RANK() OVER (ORDER BY SUM(sf.ss_net_profit) DESC) AS profit_rank
FROM sales_filtered sf
JOIN store s
    ON sf.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd
    ON sf.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON sf.ss_addr_sk = ca.ca_address_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_education_status = 'College'
  AND ca.ca_state = 'California'
GROUP BY s.s_store_name, s.s_state
HAVING SUM(sf.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10
