# “pv”:相当于点击，“buy”:商品购买，“cart”:将商品加入购物车，“fav”:收藏商品
# 减少数据
delete from userbehavior where userbehavior.user_id > 18000;
commit;
# 为表格加时间字段
alter table userbehavior add datetime datetime;
alter table userbehavior add time_date varchar(255);
alter table userbehavior add time_hour varchar(255);

# 时间戳转化标准时间函数from_unixtime()
update userbehavior set userbehavior.datetime = from_unixtime(timestamp);
update userbehavior set userbehavior.time_date = mid(userbehavior.datetime, 1 , 10);
update userbehavior set userbehavior.time_hour = right(userbehavior.datetime, 8);


# 给MySQL分配更大的内存和缓冲，以便处理海量数据，注：MySQL重启后就失效了
SET GLOBAL  tmp_table_size =1024*1024*1024;
SET GLOBAL innodb_buffer_pool_size=1073741824;

# 筛选出固定时间段里的数据
delete from userbehavior where time_date < '2017-11-25' or userbehavior.time_date > '2017-12-03';

# 检查数据
select  max(time_date), min(time_date) from userbehavior;
select count(user_id), count(item_id), count(category_id), count(Behavior),
       count(datetime), count(timestamp), count(time_date), count(time_hour)
from userbehavior;

# 计算访客数、点击数、人均点击数
select count(distinct user_id) "访客数",
       (select count(*) from userbehavior where Behavior = 'pv') '点击数',
       round((select count(*) from userbehavior where Behavior = 'pv')/count(distinct user_id), 2)
           '人均访问数'
from userbehavior;
select distinct (user_id)
	   from userbehavior;
# 为了下面代码能执行，运行这个改变 sql_mode
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
# 用户跳出率：只访问一次页面数/总用户数
/* 这部分涉及到SQL语法的知识了
   1) concat:两部分连接功能
   2）inner join是用于两个表进行联结，可以用where语法代替， 下面我就用两个语法分别写一下，看看区别你就懂了
   3）他的代码也可以学到很多东西，比如字段可以在from中定义
   4）项目中还是可以学到很多东西的*/

select 总用户数, 只访问一次页面数, concat((只访问一次页面数 * 100) / (总用户数), '%') '跳出率'
from (select user_id, count(distinct user_id) '只访问一次页面数' from userbehavior
        where user_id not in
            (select distinct user_id from userbehavior where Behavior = 'fav')
        and user_id not in
            (select distinct user_id from userbehavior where Behavior = 'cart')
        and user_id not in
            (select  distinct user_id from userbehavior where Behavior = 'buy')) as a,
     (select user_id, count(distinct user_id) '总用户数' from userbehavior) as b
WHERE a.user_id = b.user_id;

select 总用户数,只访问一次页面数,concat((只访问一次页面数 * 100) / (总用户数), '%') "跳出率"
from  (select user_id,count(distinct user_id) "只访问一次页面数"  from userbehavior
		       where user_id not in
				   (select distinct user_id from userbehavior where behavior ='fav')
					 and user_id not in
				   (select distinct user_id from userbehavior where behavior ='cart')
					 and user_id not in
				   (select distinct user_id from userbehavior where behavior ='buy')) as a
inner join (select user_id, count(distinct user_id) "总用户数" from userbehavior) as b
on a.user_id = b.user_id;

# 每日访客数，用户的点击量，收藏次数， 加入购物车次数，购买次数
# inner join和join是一个意思
# 通过数据可视化发现 周六的交易量明显上升
select a.time_date, e.访客数, a.活跃点击量, b.收藏次数, c.加入购物车次数, d.购买次数
from (select time_date, count(Behavior) '活跃点击量'
        from userbehavior
        where Behavior = 'pv' group by time_date order by time_date) as a inner join
    (select time_date, count(Behavior) '收藏次数'
        from userbehavior
        where Behavior = 'fav' group by time_date) as b inner join
    (select time_date, count(Behavior) '加入购物车次数'
        from userbehavior
        where Behavior = 'cart' group by time_date) as c inner join
    (select time_date, count(Behavior) '购买次数'
        from userbehavior
        where Behavior = 'buy' group by time_date) as d join
    (select time_date, count(distinct user_id) '访客数' from userbehavior
        group by time_date ) as e
on a.time_date = b.time_date
and b.time_date = c.time_date
and c.time_date = d.time_date
and d.time_date = e.time_date;


# 统计各个小时用户的行为
# 这里的sql用法真的太好了，记下来---按条件计数：sum(case when .... then 1 else 0 end)
# 通过可视化，18-22时购物明显上升
select mid(time_hour, 1, 2) '时间',
       sum(case when Behavior = 'pv' then 1 else 0 end) '活跃点击量',
       count(distinct user_id) '活跃用户数',
       sum(case when Behavior = 'fav' then 1 else 0 end) '收藏次数',
       sum(case when Behavior = 'cart' then 1 else 0 end) '加入购物车次数',
       sum(case when Behavior = 'buy' then 1 else 0 end) '购买次数'
from userbehavior
group by  mid(time_hour, 1, 2);

#       inner join (select UserID, count(distinct UserID) '总用户数' from userbehavior) as b
#       on a.UserID = b.UserID;
select count(distinct UserID)
from userbehavior;

# 选出销量好的产品
# 注意desc limit 用法
select item_id '商品编号', category_id '商品种类', count(Behavior) '销量'
from userbehavior
where Behavior = 'buy'
group by item_id
order by 销量 desc limit 10;
# 选出销量好的种类
select category_id '商品种类', count(Behavior) '销量'
from userbehavior
where Behavior = 'buy'
group by category_id
order by 销量 desc limit 10;


# 七天内人(消费过)的人均购买次数
# 这是原答案，但我认为不对，你统计的不是所有用户，而是购买过的用户
# select count(Behavior) as 订单量,
#        count(Behavior) / count(distinct UserID) as 人均购买次数
# from userbehavior
# where Behavior = 'buy';

# 这是我自己改的，这回就是所有用户的人均购买次数
# 让我想到我看的SQL必知必会书了 sql语句是从from开始执行的，所以from句子里的字段引用可以用别名，select里的不行
# 还有就是sql的技巧了，如果两个字段条件不一样怎么怎么合到一起，就用from select子句
select count(distinct user_id) as 用户数, a.订单量, a.订单量 / count(distinct user_id) as 人均购买次数
from userbehavior,
     (select count(Behavior) as 订单量
        from userbehavior
        where Behavior = 'buy') as a;

# 复购率=购买2次及以上用户数/总购买用户数
# 加as的意思是每个派生表必须有个自己的名字，也就是from里你用select组成新表了，最后一般都加个as
select 购买用户数, 购买两次及以上用户数, concat(购买两次及以上用户数 * 100 / 购买用户数, '%') as 复购率
from(
    select count(distinct user_id) as 购买用户数,
           (select count(*) as 购买两次及以上用户数1
               from(select count(user_id) as 重复购买次数
                    from userbehavior
                    where Behavior = 'buy'
                    group by user_id
                    having count(user_id) > 1) as b) as 购买两次及以上用户数
    from userbehavior
    where Behavior = 'buy') as c;

# 经常消费的重点客户（次数和金额）
select user_id, count(user_id) as 购买次数
from userbehavior
where Behavior = 'buy'
group by user_id
order by count(user_id) desc
limit 10;

# 用户行为转化分析
# 这个学到了tableau的一个很好的用法-漏斗图
select  Behavior as 用户行为, count(Behavior) as 用户行为次数
from userbehavior
group by Behavior
order by count(Behavior) desc;

# 点击-收藏-购买的转化路径分析
# 这个有点稍微难理解，自己是很难写出来了，但是大概能看懂，每个子表无非有两个条件，一个是行为，一个是时间，left
#join 就是把左表的数据全部都算进去
# 还有就是字段我把distinct删除了，我认为根据实际情况转化路径应该全算上，而不是每个用户算一次
# 还是加上distinct吧，我大致明白作者为什么这么写了，它是想以人为单位，来分析每个人的行为。
select count(distinct a.user_id) '点击数',
       count(distinct b.user_id) '收藏数',
       count(distinct c.user_id) '购买数'
from (select distinct user_id, item_id, category_id, timestamp from userbehavior where Behavior = 'pv') as a
     left join
     (select distinct user_id, item_id, category_id, timestamp from userbehavior where Behavior = 'fav') as b
     on (a.user_id = b.user_id and a.item_id = b.item_id and a.category_id = b.category_id and a.timestamp < b.timestamp)
     left join
     (select distinct user_id, item_id, category_id, timestamp from userbehavior where Behavior = 'buy') as c
     on (b.user_id = c.user_id and b.item_id = c.item_id and b.category_id = c.category_id and b.timestamp < c.timestamp);

# 点击-加入购物车-购买的转化路径分析
# 通过这个路径购买的人更多
select count(distinct a.user_id) '点击数',
       count(distinct b.user_id) '加入购物车数',
       count(distinct c.user_id) '购买数'
from (select distinct user_id, item_id, category_id, timestamp from userbehavior where Behavior = 'pv') as a
    left join
     (select distinct user_id, item_id, category_id, timestamp from userbehavior where Behavior = 'cart') as b
    on (a.user_id = b.user_id and a.item_id = b.item_id and a.category_id=b.category_id and a.timestamp<b.timestamp)
     left join
    (select distinct user_id, item_id, category_id, timestamp from userbehavior where Behavior = 'buy') as c
    on (b.user_id = c.user_id and b.item_id = c.item_id and b.category_id = c.category_id and b.timestamp<c.timestamp);

# 商品种类点击量排名前十
select category_id 商品种类, count(category_id) as 点击次数
from userbehavior
where Behavior = 'pv'
group by category_id
order by 点击次数 desc
limit 10;

# 商品点击量排名前十
select item_id 商品ID, category_id 商品所属种类, count(item_id) as 点击次数
from userbehavior
where Behavior = 'pv'
group by item_id
order by 点击次数 desc
limit 10;

# 查询点击量前十的购买率（这个思想我感觉很好，通过这个数据就可以看到，给用户推得商品是不是他们要买的）
select distinct u3.item_id 商品ID,
       u3.点击次数, count(u1.item_id) as 购买次数,
       concat((count(u1.item_id) * 100) / u3.点击次数, '%') as 购买率
from userbehavior u1,
     (select item_id, category_id, count(item_id) 点击次数
      from userbehavior
      where Behavior = 'pv'
      group by item_id
      order by 点击次数 desc
      limit 10) u3
where u1.item_id = u3.item_id
and Behavior = 'buy'
group by u3.item_id
order by u3.点击次数 desc;

# 消费间隔R的得分(作者这里做的更像是最近购买时间)
# datediff(date1, date2) = date1 -date2
# 这里的消费间隔应该是最近购买-上次购买，而不是作者写的最近一次购买-数据第一天，可能是原问题比较难写2把
create view score_R as
select user_id,
       (case when 购买天数 between 0 and 1 then 1
           when 购买天数 between 2 and 3 then 2
           when 购买天数 between 4 and 5 then 3
           when 购买天数 = 6 then 4 else 0 end) as 购买得分
from (
     select user_id, datediff(max(time_date), '2017-11-26') as 购买天数
    from userbehavior
    where Behavior = 'buy'
    group by user_id) as a
    order by 购买得分 desc;

# 购买频率F的得分
create view score_F as
select user_id,
       (case when 购买次数 between 0 and 10 then 1
           when 购买次数 between 11 and 20 then 2
           when 购买次数 between 21 and 30 then 3
           when 购买次数 between 31 and 50 then 4 else 0 end) as 购买频率得分
from (select user_id, count(Behavior) as 购买次数
      from userbehavior
      where Behavior = 'buy'
      group by user_id) b
order by 购买频率得分 desc;

# 将获得的两项评分分别和它们的均值进行比较，对客户进行分类
select avg(购买得分) 平均购买得分
from score_r;
select avg(购买频率得分) 平均购买频率得分
from score_f;
create view users_classify as
select user_id,
       (case when R>3 and F>1 then '重要价值用户'
        when R>3 and F<=1 then '重要保持用户'
        when R<=3 and F>1 then '重要发展用户'
        when R<=3 and F<=1 then '一般价值用户' else 0 end) as 用户类型
from (select a.user_id, a.购买得分 as R, b.购买频率得分 as F
    from score_r as a inner join score_f as b
    on a.user_id = b.user_id) c;

# 用户类型计数
/*对于重要价值用户，他们是最优质的用户，需要重点关注并保持， 应该提高满意度，增加留存；
对于重要保持用户，他们最近有购买，但购买频率不高，可以通过活动等提高其购买频率；
对于重要发展用户，他们虽然最近没有购买，但以往购买频率高，可以做触达，以防止流失；
对于一般价值用户，他们最近没有购买，以往购买频率也不高，特别容易流失，所以应该赠送优惠券或推送活动信息，唤醒购买意愿。
*/
select count(用户类型) 重要价值用户, a.a 重要保持用户, b.b 重要发展用户, c.c 一般价值用户
from users_classify,
     (select count(用户类型) a from users_classify where 用户类型 = '重要保持用户') as a,
     (select count(用户类型) b from users_classify where 用户类型 = '重要发展用户') as b,
     (select count(用户类型) c from users_classify where 用户类型 = '一般价值用户') as c
where 用户类型 = '重要价值用户';


