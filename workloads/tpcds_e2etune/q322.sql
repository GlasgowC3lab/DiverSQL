WITH store_demo_agg AS (
    SELECT
        s.s_store_name,
        s.s_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset = -5.00
      AND sr.sr_return_amt_inc_tax > 100
      AND s.s_state IN ('AZ', 'CO')
    GROUP BY s.s_store_name, s.s_state, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(sr.sr_return_amt_inc_tax) > 500
)
SELECT
    s_store_name,
    s_state,
    cd_gender,
    cd_marital_status,
    distinct_customers,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    RANK() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS state_rank
FROM store_demo_agg
ORDER BY total_net_loss DESC
LIMIT 10
