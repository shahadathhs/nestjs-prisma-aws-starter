-- CreateTable
CREATE TABLE "video_merge_jobs" (
    "id" TEXT NOT NULL,
    "jobId" TEXT NOT NULL,
    "outputUrl" TEXT NOT NULL,
    "outputFileId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'SUBMITTED',
    "errorMessage" TEXT,
    "sourceFileIds" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "video_merge_jobs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "video_merge_jobs_jobId_key" ON "video_merge_jobs"("jobId");

-- CreateIndex
CREATE UNIQUE INDEX "video_merge_jobs_outputFileId_key" ON "video_merge_jobs"("outputFileId");

-- AddForeignKey
ALTER TABLE "video_merge_jobs" ADD CONSTRAINT "video_merge_jobs_outputFileId_fkey" FOREIGN KEY ("outputFileId") REFERENCES "file_instances"("id") ON DELETE SET NULL ON UPDATE CASCADE;
