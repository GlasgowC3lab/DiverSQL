WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        i.i_brand,
        c.c_customer_sk,
        c.c_customer_id,
        hd.hd_buy_potential,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        inv.inv_quantity_on_hand,
        ws.ws_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND c.c_birth_year = 1955
      AND hd.hd_income_band_sk = 5
      AND inv.inv_quantity_on_hand > 500
      AND sr.sr_fee > 20.00
      AND ws.ws_net_profit > 0
),
agg AS (
    SELECT
        d_year,
        i_brand,
        hd_buy_potential,
        COUNT(DISTINCT c_customer_sk) AS cnt_customers,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(sr_return_amt) AS total_returns,
        AVG(inv_quantity_on_hand) AS avg_inventory,
        MAX(ws_net_profit) AS max_profit
    FROM joined
    GROUP BY d_year, i_brand, hd_buy_potential
    HAVING SUM(ss_ext_sales_price) > 10000
       AND COUNT(DISTINCT c_customer_sk) > 5
)
SELECT
    d_year,
    i_brand,
    hd_buy_potential,
    cnt_customers,
    total_sales,
    total_returns,
    avg_inventory,
    max_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rn
FROM agg
ORDER BY total_sales DESC
LIMIT 100
