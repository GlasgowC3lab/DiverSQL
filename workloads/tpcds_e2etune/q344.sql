WITH recent_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_returned_date_sk,
        sr.sr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_refunded_cash,
        sr.sr_return_tax
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450200
),
customer_returns AS (
    SELECT
        rr.*,
        c.c_birth_year,
        c.c_preferred_cust_flag
    FROM recent_returns rr
    JOIN customer c ON rr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
),
store_demo_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        cd.cd_gender,
        SUM(cr.sr_net_loss) AS total_net_loss,
        AVG(cr.sr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT cr.sr_customer_sk) AS unique_customers,
        SUM(cr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS total_returns
    FROM customer_returns cr
    JOIN store s ON cr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON cr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY s.s_store_id, s.s_state, cd.cd_gender
),
ranked_stores AS (
    SELECT
        s_store_id,
        s_state,
        cd_gender,
        total_net_loss,
        avg_return_amount,
        unique_customers,
        total_return_qty,
        total_returns,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_loss DESC) AS loss_rank
    FROM store_demo_agg
)
SELECT
    s_store_id,
    s_state,
    cd_gender,
    total_net_loss,
    avg_return_amount,
    unique_customers,
    total_return_qty,
    total_returns,
    loss_rank
FROM ranked_stores
WHERE loss_rank <= 5
ORDER BY cd_gender, loss_rank
