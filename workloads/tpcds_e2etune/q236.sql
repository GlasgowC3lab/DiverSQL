WITH sales_agg AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           p.p_channel_email,
           d.d_year,
           d.d_moy AS month,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_ext_discount_amt) AS total_discount,
           COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
      AND p.p_discount_active = 'Y'
      AND c.c_birth_year >= 1970
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_channel_email, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT p.p_promo_sk,
           d.d_year,
           d.d_moy AS month,
           SUM(sr.sr_net_loss) AS total_return_loss,
           COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
      AND c.c_birth_year >= 1970
    GROUP BY p.p_promo_sk, d.d_year, d.d_moy
)
SELECT s.p_promo_name,
       s.p_channel_email,
       s.d_year,
       s.month,
       s.total_net_profit,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
       SUM(s.total_net_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.p_promo_sk ORDER BY s.d_year, s.month) AS cumulative_profit,
       s.total_discount,
       CASE WHEN s.total_discount <> 0 THEN (s.total_net_profit - COALESCE(r.total_return_loss, 0)) / s.total_discount ELSE NULL END AS profit_to_discount_ratio,
       s.num_transactions,
       COALESCE(r.num_returns, 0) AS num_returns
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.p_promo_sk = r.p_promo_sk
 AND s.d_year = r.d_year
 AND s.month = r.month
ORDER BY net_profit_after_returns DESC
LIMIT 100
