WITH unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_quantity AS quantity,
        ss.ss_hdemo_sk AS hdemo_sk,
        ss.ss_addr_sk AS addr_sk,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_quantity AS quantity,
        ws.ws_bill_hdemo_sk AS hdemo_sk,
        ws.ws_bill_addr_sk AS addr_sk,
        'web' AS channel
    FROM web_sales ws
)
SELECT
    year,
    state,
    income_lower,
    income_upper,
    total_profit,
    total_paid,
    avg_discount,
    total_quantity,
    sales_count,
    total_profit / sum(total_profit) OVER (PARTITION BY year) AS profit_share,
    rank() OVER (PARTITION BY year ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(us.net_profit) AS total_profit,
        SUM(us.net_paid) AS total_paid,
        AVG(us.discount_amt) AS avg_discount,
        SUM(us.quantity) AS total_quantity,
        COUNT(*) AS sales_count
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON us.hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON us.addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(us.net_profit) > 10000
) t
ORDER BY year, profit_rank
LIMIT 50
