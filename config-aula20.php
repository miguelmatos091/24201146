<?php
// config.php — em produção, mantenha FORA da pasta pública e use variáveis de ambiente (.env).
$host = 'localhost';          // com Docker Compose, use o nome do serviço (ex.: 'mysql')
$db   = 'escola';
$user = 'app_escola';         // nunca root
$pass = 'senha_forte';

$pdo = new PDO(
    "mysql:host=$host;dbname=$db;charset=utf8mb4",
    $user,
    $pass,
    [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]
);
