-- AlterTable
CREATE UNIQUE INDEX "Chat_instanceId_remoteJid_key" ON "Chat"("instanceId", "remoteJid");
