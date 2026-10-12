WITH returns_agg AS (
    SELECT i.i_brand AS brand,
           ca.ca_state AS state,
           hd.hd_income_band_sk AS income_band,
           SUM(sr.sr_net_loss) AS total_return_loss,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1990
      AND ca.ca_country = 'United States'
    GROUP BY i.i_brand, ca.ca_state, hd.hd_income_band_sk
),
sales_agg AS (
    SELECT i.i_brand AS brand,
           ca.ca_state AS state,
           hd.hd_income_band_sk AS income_band,
           SUM(ws.ws_net_paid_inc_tax) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1990
      AND ca.ca_country = 'United States'
      AND ws.ws_sold_date_sk >= 2450000
    GROUP BY i.i_brand, ca.ca_state, hd.hd_income_band_sk
)
SELECT r.brand,
       r.state,
       r.income_band,
       r.total_return_loss,
       s.total_sales,
       s.total_profit,
       CASE WHEN s.total_profit > 0 THEN r.total_return_loss / s.total_profit ELSE NULL END AS loss_to_profit_ratio,
       r.return_cnt,
       s.sales_cnt
FROM returns_agg r
LEFT JOIN sales_agg s
  ON r.brand = s.brand
 AND r.state = s.state
 AND r.income_band = s.income_band
ORDER BY loss_to_profit_ratio DESC NULLS LAST
LIMIT 100
