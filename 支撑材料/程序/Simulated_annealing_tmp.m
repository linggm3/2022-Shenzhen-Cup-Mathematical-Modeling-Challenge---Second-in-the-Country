function [dot, cost, run_time, counter] = Simulated_annealing_tmp(T, innerloop, dc, dot, supply, center, center_load, spacing, boxx, boxy, counter, ttt)
% 模拟退火算法
global idx; global x;  global y; 
color = [0,0,0; 0,0,255; 0,255,0; 255,0,0] / 255;
previous_cost = cost_fun(cat(1, supply, dot), center, center_load);
epoch = 0; % 外层循环计数器
cost_4 = 2.6 * 35 + 56.8 * 7;
mkdir("D:\picture\pic" + num2str(ttt)); % 创建文件夹
% 开始退火
tic;
while T > 0.01
     % 扰动：
        new_dot = dot_disturb(dot, boxx, boxy, spacing);
        % 计算扰动后的cost
        new_cost = cost_fun(cat(1, supply, new_dot), center, center_load) ;
        delta_cost = new_cost - previous_cost;
        if delta_cost < 0
            dot = new_dot;
            previous_cost = new_cost;
        else
            if exp(-delta_cost/T)>rand()
               dot = new_dot;
               previous_cost = new_cost;
            end
        end
    epoch = epoch + 1;
    cost(epoch) = previous_cost;
    run_time(epoch) = toc;
    T = T * dc; % 退温系数
    if mod(epoch, 50) == 0
        fprintf("---退火第%d轮迭代---\n", epoch);
        fprintf("  目前温度为%.2f\n", T);
        fprintf("  目前花费为%.2f\n", previous_cost);
    end

    if mod(epoch, 50) == 1
        dot = [cat(1, dot, supply); [25287.5,-13343.7]./1000];
        dotx = dot(:, 1)';
        doty = dot(:, 2)';
        [~, edge] = minspan(dot);
        figure;
        title("双层规划效果图");
        hold on;
        scatter(center(:, 1), center(:, 2), 200);
        hold on;
        scatter(supply(1), supply(2), 700);
        hold on;
        line([dotx(edge(:, 1)); dotx(edge(:, 2))], [doty(edge(:, 1)); doty(edge(:, 2))], 'Color', color(1, :), 'LineWidth', 4)
        hold on;
        
         % 计算费用
        % 计算一级支线费用
        d = zeros(1, size(edge, 1));
        for ii = 1:7
            for j = 1:size(edge, 1)
                % 二级分叉点到总线每段的距离
                [d(1, j), nearest(j, :)] = distance_fun(center(ii, :), dot(edge(j, 1), :), dot(edge(j, 2), :) );
            end
            [~, pos] = min(d);
            res(ii, :) = nearest(pos, :);
            hold on;
            line([res(ii, 1); center(ii, 1)], [res(ii, 2); center(ii, 2)], 'Color', color(2, :), 'LineWidth', 3)
        end

        cost_1 = 0; cost_2 = 0; cost_3 = 0; 
        for i = 1:7 % 对第一层的每个聚类中心
            % 将第一层聚类的每个簇提取出来
            cluster{i} = [x(idx == i)', y(idx == i)'];
    
            % 根据每簇的点个数 进行 第二层聚类
            clear SilhouetteCoefficient;
            for n = 1:ceil(center_load(i) / 2 + 1)
                [idx2{i}, center2{i}] = kmeans(cluster{i}, n, 'Replicates', 200);
                SilhouetteCoefficient(n) = mean(silhouette(cluster{i}, idx2{i}) );
                if center_load(i) == 1
                    break;
                end
            end
            [~, cluster2_num] = max(SilhouetteCoefficient);
            [idx2{i}, center2{i}] = kmeans(cluster{i}, cluster2_num, 'Replicates', 500);
            center2_load{i} = count_num(idx2{i}, cluster2_num);
            cluster2{i} = cell(1, cluster2_num);
            for t = 1:cluster2_num
                cluster2{i}{t} = cluster{i}(idx2{i} == t, :);
            end
    
    
            hold on;
            %     scatter(center2{i}(:, 1), center2{i}(:, 2), 100);
    
    
            % 以 一级支线的费用和二级支线的费用最小为目标 优化二级分叉点
            point = center;
    
            % 计算费用
            % 计算一级支线费用
            d = zeros(1, size(edge, 1));
            for j = 1:size(edge, 1)
                % 二级分叉点到总线每段的距离
                [d(1, j), nearest(j, :)] = distance_fun(point(i, :), dot(edge(j, 1), :), dot(edge(j, 2), :) );
            end
            % 二级分叉点到总线的最短距离
            [distance, min_index] = min(d);        
            hold on;
            line([point(i, 1), nearest(min_index, 1)], [point(i, 2), nearest(min_index, 2)], 'Color', color(2, :), 'LineWidth', 3);
    
            if center_load(i) >= 3
                weight = 239.4; % 支线B
            else
                weight = 188.6; % 支线A
            end
            % 加上一级支线的价格
            cost_1 = cost_1 + weight * distance;
    
            % 计算二级支线费用
            for j = 1:cluster2_num % 对第二层聚类的每簇
                % 第i簇里面的第j簇的负荷数
                if center2_load{i}(j) >= 3
                    weight = 239.4; % 支线B
                else
                    weight = 188.6; % 支线A
                end
                cost_2 = cost_2 + weight * dist(point(i, :), center2{i}(j, :)');
                hold on;
%                 line([point(i, 1), center2{i}(j, 1)], [point(i, 2), center2{i}(j, 2)], 'Color', color(3, :), 'LineWidth', 2);
    
                % 计算三级支线费用
                weight = 188.6; % 支线A
                distance = dist(cluster{i}(idx2{i} == j, :), center2{i}(j, :)');
                cost_3 = cost_3 + weight * sum(distance);
    
                for k = 1:center2_load{i}(j) % 对第二层每簇的每个点
                    box_tmp = cluster{i}(idx2{i} == j, :);
                    hold on; % 画图，连线
%                     line([box_tmp(k, 1), center2{i}(j, 1)], [box_tmp(k, 2), center2{i}(j, 2)], 'Color', color(4, :), 'LineWidth', 1);
                end
    
            end
    
        end
    
        [~, ~, main_line_length] = cost_fun(dot, center, center_load);
        cost_main = 325.7 * main_line_length;
        fprintf("最终花费%f千元\n", cost_1 + cost_2 + cost_3 + cost_4 + cost_main);
        total_cost = cost_1 + cost_2 + cost_3 + cost_4 + cost_main;
        hold on;
        text(1.20, 2.3, '模拟退火', 'FontSize', 16)
        text(1.20, 2.0, '规划费用', 'FontSize', 16)
        text(1.23, 1.7, num2str(round(cost(epoch), 2)), 'FontSize', 16)
        text(1.20, 1.4, '总体费用', 'FontSize', 16)
        text(1.23, 1.1, num2str(round(total_cost, 2)), 'FontSize', 16)
        hold on;
        scatter(x, y);
        axis([-1.75, 2.25, -1.5, 2.5]);
      
        h1=gcf ;
        saveas(h1, "D:\picture\pic" + num2str(ttt) + "\picture" + num2str(counter) + ".jpg");
        counter = counter + 1;
        dot = dot(1:20, :);
    end
    
end
toc;

% figure;
% plot(cost);
% title('模拟退火算法下解的变动情况');
% xlabel('迭代次数');
% ylabel('费用');

return;