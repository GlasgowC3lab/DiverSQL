WITH sales AS (
    SELECT
        ss.ss_promo_sk,
        d.d_year,
        d.d_moy,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450900 AND 2451200
    GROUP BY ss.ss_promo_sk, d.d_year, d.d_moy, ca.ca_state
),
store_ret AS (
    SELECT
        ss.ss_promo_sk,
        d.d_year,
        d.d_moy,
        ca.ca_state,
        SUM(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY ss.ss_promo_sk, d.d_year, d.d_moy, ca.ca_state
),
catalog_ret AS (
    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_reason_sk = 51
      AND cr.cr_returned_date_sk = 2451132
    GROUP BY d.d_year, d.d_moy, ca.ca_state
)
SELECT
    p.p_promo_name,
    s.d_year,
    s.d_moy AS month,
    s.ca_state AS state,
    COALESCE(s.total_net_paid, 0) AS total_net_paid,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    (COALESCE(s.total_net_profit, 0) - COALESCE(sr.total_store_return_loss, 0) - COALESCE(cr.total_catalog_return_loss, 0)) AS adjusted_net_profit,
    CASE 
        WHEN COALESCE(s.total_net_paid, 0) = 0 THEN NULL
        ELSE (COALESCE(sr.total_store_return_loss, 0) + COALESCE(cr.total_catalog_return_loss, 0)) / COALESCE(s.total_net_paid, 0) * 100
    END AS loss_rate_percent,
    ROW_NUMBER() OVER (PARTITION BY s.ca_state ORDER BY (COALESCE(s.total_net_profit, 0) - COALESCE(sr.total_store_return_loss, 0) - COALESCE(cr.total_catalog_return_loss, 0)) DESC) AS profit_rank_state
FROM sales s
LEFT JOIN store_ret sr
    ON s.ss_promo_sk = sr.ss_promo_sk
    AND s.d_year = sr.d_year
    AND s.d_moy = sr.d_moy
    AND s.ca_state = sr.ca_state
LEFT JOIN catalog_ret cr
    ON s.d_year = cr.d_year
    AND s.d_moy = cr.d_moy
    AND s.ca_state = cr.ca_state
JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
ORDER BY adjusted_net_profit DESC
LIMIT 100
