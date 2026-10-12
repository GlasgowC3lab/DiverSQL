WITH demographic_sales AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd_bill.cd_marital_status,
        cd_bill.cd_gender,
        cd_bill.cd_credit_rating,
        sum(ws.ws_net_profit) AS total_net_profit,
        avg(ws.ws_net_paid) AS avg_net_paid,
        sum(ws.ws_quantity) AS total_quantity,
        count(DISTINCT ws.ws_order_number) AS order_count,
        avg(cd_ship.cd_dep_count) AS avg_ship_dependents
    FROM web_sales ws
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN income_band ib
        ON cd_bill.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE cd_bill.cd_gender = 'F'
      AND cd_bill.cd_credit_rating = 'Good'
      AND cd_bill.cd_purchase_estimate >= 1500
      AND cd_bill.cd_dep_count >= 2
      AND cd_ship.cd_credit_rating <> 'Low Risk'
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd_bill.cd_marital_status,
        cd_bill.cd_gender,
        cd_bill.cd_credit_rating
    HAVING sum(ws.ws_net_profit) > 10000
)
SELECT
    ds.ib_income_band_sk,
    concat(cast(ds.ib_lower_bound as varchar), '-', cast(ds.ib_upper_bound as varchar)) AS income_band_range,
    ds.cd_marital_status,
    ds.cd_gender,
    ds.cd_credit_rating,
    ds.total_net_profit,
    ds.avg_net_paid,
    ds.total_quantity,
    ds.order_count,
    ds.avg_ship_dependents,
    ds.total_net_profit / ds.avg_net_paid AS profit_per_paid_ratio,
    rank() OVER (ORDER BY ds.total_net_profit DESC) AS profit_rank
FROM demographic_sales ds
ORDER BY ds.total_net_profit DESC
LIMIT 10
