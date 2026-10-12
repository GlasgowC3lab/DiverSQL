WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
      ON d.d_date_sk >= cc.cc_open_date_sk
     AND (cc.cc_closed_date_sk IS NULL OR d.d_date_sk <= cc.cc_closed_date_sk)
    WHERE d.d_year = 2002
      AND cc.cc_class = 'large'
      AND cc.cc_gmt_offset = -5.00
    GROUP BY d.d_year, d.d_month_seq, hd.hd_buy_potential
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        hd.hd_buy_potential,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE dr.d_year = 2002
    GROUP BY dr.d_year, dr.d_month_seq, hd.hd_buy_potential
)
SELECT
    t.d_year,
    t.d_month_seq,
    t.hd_buy_potential,
    t.total_sales,
    t.total_profit,
    t.total_return_amt,
    t.return_rate,
    t.profit_rank
FROM (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.hd_buy_potential,
        s.total_sales,
        s.total_profit,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amt, 0) / s.total_sales ELSE 0 END AS return_rate,
        ROW_NUMBER() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_profit DESC) AS profit_rank
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
       AND s.hd_buy_potential = r.hd_buy_potential
) t
WHERE t.profit_rank <= 3
ORDER BY t.d_year, t.d_month_seq, t.profit_rank
