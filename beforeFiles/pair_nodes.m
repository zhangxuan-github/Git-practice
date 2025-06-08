function pairs = pair_nodes(dist_matrix)
[~, closest_servers] = min(dist_matrix, [], 2);
pairs = closest_servers;
end
