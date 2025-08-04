<?php

require __DIR__ . '/vendor/autoload.php';

use Telegram\Bot\Api;
use Telegram\Bot\Keyboard\Keyboard;
use Telegram\Bot\Objects\Update;
use Aws\DynamoDb\DynamoDbClient;
use Aws\Sdk;
use Aws\DynamoDb\Exception\DynamoDbException;

const TELEGRAM_BOT_TOKEN = '8453831783:AAFtsSVLCCh4bmxl4MhTG9yFOsk1_i23cag';

// --- Configuração do DynamoDB ---
// O SDK da AWS pegará as credenciais e região do ambiente Lambda automaticamente.
$sdk = new Sdk([
    'region'   => 'us-east-2', // Região definida para Ohio
    'version'  => 'latest'
]);
$dynamoDbClient = $sdk->createDynamoDb();
const DYNAMODB_TABLE_NAME = 'BotClicks'; // Nome da sua tabela DynamoDB

$telegram = new Api(TELEGRAM_BOT_TOKEN);

try {
    $update = $telegram->getWebhookUpdate();

    if ($update->getMessage() && $update->getMessage()->getText()) {
        $message = $update->getMessage();
        $chatId = $message->getChat()->getId();
        $command = $message->getText();

        if ($command === '/enviar_link') {
            $linkUrl = "https://www.google.com/search?q=rastreamento+de+links+telegram";
            $linkId = "meu_link_rastreavel_abc";

            $keyboard = Keyboard::make()->inline()
                ->row([
                    Keyboard::inlineButton(['text' => 'Clique para Acessar o Link!', 'url' => $linkUrl, 'callback_data' => "click_{$linkId}"])
                ]);

            $telegram->sendMessage([
                'chat_id'      => $chatId,
                'text'         => '🔗 **Novo Link Rastreado!** Clique no botão abaixo para acessar:',
                'reply_markup' => $keyboard,
                'parse_mode'   => 'Markdown'
            ]);
            error_log("Comando /enviar_link executado. Link '{$linkUrl}' com ID '{$linkId}' enviado para o chat {$chatId}.");
        }
    }

    if ($update->getCallbackQuery()) {
        $callbackQuery = $callbackQuery = $update->getCallbackQuery();
        $callbackData = $callbackQuery->getData();
        $queryId = $callbackQuery->getId();

        if (str_starts_with($callbackData, 'click_')) {
            $linkId = str_replace('click_', '', $callbackData);

            // --- REGISTRO DO CLIQUE NO DYNAMODB ---
            $userId = $callbackQuery->getFrom()->getId();
            $username = $callbackQuery->getFrom()->getUsername() ?? 'N/A';
            $firstName = $callbackQuery->getFrom()->getFirstName();
            $currentTime = date('Y-m-d H:i:s');

            $item = [
                'linkId'    => ['S' => $linkId],
                'timestamp' => ['S' => $currentTime],
                'userId'    => ['S' => (string)$userId],
                'username'  => ['S' => $username],
                'firstName' => ['S' => $firstName],
                'queryId'   => ['S' => $queryId]
            ];

            $params = [
                'TableName' => DYNAMODB_TABLE_NAME,
                'Item' => $dynamoDbClient->marshalItem($item)
            ];

            try {
                $dynamoDbClient->putItem($params);
                error_log("Clique registrado no DynamoDB: Link ID: {$linkId}, User ID: {$userId}");
            } catch (DynamoDbException $e) {
                error_log("Erro ao gravar no DynamoDB: " . $e->getMessage() . " - Code: " . $e->getStatusCode());
            } catch (Exception $e) {
                error_log("Erro inesperado ao gravar no DynamoDB: " . $e->getMessage());
            }
            // --- FIM DO REGISTRO ---

            $telegram->answerCallbackQuery([
                'callback_query_id' => $queryId,
                'text'              => 'Obrigado por clicar!',
                'show_alert'        => false,
                'cache_time'        => 0
            ]);
        }
    }

} catch (Exception $e) {
    error_log("Erro Crítico no Webhook: " . $e->getMessage() . " - Trace: " . $e->getTraceAsString());
}

http_response_code(200);

?>
