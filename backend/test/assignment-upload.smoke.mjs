import 'dotenv/config';
import { randomUUID } from 'node:crypto';
import { unlink } from 'node:fs/promises';
import path from 'node:path';
import { PrismaClient } from '@prisma/client';

const apiBase = process.env.LMS_TEST_API_URL ?? 'http://localhost:3001/api/v1';
const base = new URL(apiBase);
const fileName = `rubric-smoke-${randomUUID()}.txt`;
const content = 'Rubric upload smoke check';
let localFile;
let localAudioFile;
const localArchiveFiles = [];
let assignmentId;

try {
  const loginResponse = await fetch(
    new URL(`${base.pathname}/auth/login`, base.origin),
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        identifier: 'GV-0001',
        password: process.env.DEMO_PASSWORD ?? 'Password@123',
      }),
    },
  );
  if (!loginResponse.ok)
    throw new Error(`Login failed: ${loginResponse.status}`);
  const login = await loginResponse.json();
  const token = login.data?.accessToken;
  if (!token) throw new Error('Login did not return an access token');

  const form = new FormData();
  form.append('folder', 'assignments');
  form.append('file', new Blob([content], { type: 'text/plain' }), fileName);
  const uploadResponse = await fetch(
    new URL(`${base.pathname}/upload`, base.origin),
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: form,
    },
  );
  if (!uploadResponse.ok) {
    throw new Error(
      `Upload failed: ${uploadResponse.status} ${await uploadResponse.text()}`,
    );
  }
  const upload = await uploadResponse.json();
  const url = upload.data?.url;
  if (!url?.startsWith('/uploads/assignments/')) {
    throw new Error(
      'Expected a local upload URL; run with Firebase credentials disabled',
    );
  }
  const uploadRoot = path.resolve(process.cwd(), 'uploads', 'assignments');
  localFile = path.resolve(uploadRoot, path.basename(url));
  if (!localFile.startsWith(`${uploadRoot}${path.sep}`)) {
    throw new Error('Unexpected uploaded file path');
  }
  const downloaded = await fetch(new URL(url, base.origin));
  if (!downloaded.ok || (await downloaded.text()) !== content) {
    throw new Error('Uploaded file could not be downloaded intact');
  }

  const audioName = `speaking-smoke-${randomUUID()}.wav`;
  const wavHeader = Buffer.alloc(44);
  wavHeader.write('RIFF', 0);
  wavHeader.writeUInt32LE(36, 4);
  wavHeader.write('WAVEfmt ', 8);
  wavHeader.writeUInt32LE(16, 16);
  wavHeader.writeUInt16LE(1, 20);
  wavHeader.writeUInt16LE(1, 22);
  wavHeader.writeUInt32LE(16000, 24);
  wavHeader.writeUInt32LE(32000, 28);
  wavHeader.writeUInt16LE(2, 32);
  wavHeader.writeUInt16LE(16, 34);
  wavHeader.write('data', 36);
  wavHeader.writeUInt32LE(0, 40);
  const audioForm = new FormData();
  audioForm.append('folder', 'assignments');
  audioForm.append(
    'file',
    new Blob([wavHeader], { type: 'audio/x-wav' }),
    audioName,
  );
  const audioResponse = await fetch(
    new URL(`${base.pathname}/upload`, base.origin),
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: audioForm,
    },
  );
  if (!audioResponse.ok) {
    throw new Error(
      `WAV upload failed: ${audioResponse.status} ${await audioResponse.text()}`,
    );
  }
  const audioUpload = await audioResponse.json();
  const audioUrl = audioUpload.data?.url;
  if (!audioUrl?.startsWith('/uploads/assignments/')) {
    throw new Error('WAV upload did not return a local assignment URL');
  }
  localAudioFile = path.resolve(uploadRoot, path.basename(audioUrl));
  for (const [extension, mime] of [
    ['zip', 'application/x-zip-compressed'],
    ['rar', 'application/vnd.rar'],
  ]) {
    const archiveName = `archive-smoke-${randomUUID()}.${extension}`;
    const archiveForm = new FormData();
    archiveForm.append('folder', 'assignments');
    archiveForm.append('file', new Blob([content], { type: mime }), archiveName);
    const archiveResponse = await fetch(
      new URL(`${base.pathname}/upload`, base.origin),
      { method: 'POST', headers: { Authorization: `Bearer ${token}` }, body: archiveForm },
    );
    if (!archiveResponse.ok) {
      throw new Error(`${extension.toUpperCase()} upload failed: ${archiveResponse.status} ${await archiveResponse.text()}`);
    }
    const archive = await archiveResponse.json();
    localArchiveFiles.push(path.resolve(uploadRoot, path.basename(archive.data.url)));
  }
  const classesResponse = await fetch(
    new URL(`${base.pathname}/my/classes`, base.origin),
    {
      headers: { Authorization: `Bearer ${token}` },
    },
  );
  if (!classesResponse.ok) throw new Error('Could not load teacher classes');
  const classes = await classesResponse.json();
  const classId = classes.data?.find(
    (item) => item.code === 'DEMO-IELTS-2026',
  )?.id;
  if (!classId) throw new Error('Demo IELTS class is missing');

  const title = `Upload smoke ${randomUUID()}`;
  const createResponse = await fetch(
    new URL(`${base.pathname}/classes/${classId}/assignments`, base.origin),
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        title,
        type: 'HOMEWORK',
        maxScore: 10,
        attachments: [
          { name: fileName, url, fileType: 'DOCUMENT', size: content.length },
        ],
      }),
    },
  );
  if (!createResponse.ok) {
    throw new Error(`Assignment create failed: ${createResponse.status}`);
  }
  const created = await createResponse.json();
  assignmentId = created.data?.id;
  if (
    created.data?.title !== title ||
    created.data?.attachments?.[0]?.name !== fileName
  ) {
    throw new Error(
      'Created assignment did not preserve the attachment object',
    );
  }
  const editedTitle = `${title} edited`;
  const updateResponse = await fetch(
    new URL(`${base.pathname}/assignments/${assignmentId}`, base.origin),
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        title: editedTitle,
        description: 'Updated instructions https://example.com',
        maxScore: 20,
        attachments: [
          { name: fileName, url, fileType: 'DOCUMENT', size: content.length },
        ],
      }),
    },
  );
  if (!updateResponse.ok) {
    throw new Error(
      `Assignment update failed: ${updateResponse.status} ${await updateResponse.text()}`,
    );
  }
  const detailResponse = await fetch(
    new URL(`${base.pathname}/assignments/${assignmentId}`, base.origin),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  const detail = await detailResponse.json();
  if (
    detail.data?.assignment?.title !== editedTitle ||
    Number(detail.data?.assignment?.maxScore) !== 20 ||
    detail.data?.assignment?.attachments?.[0]?.url !== url
  ) {
    throw new Error(
      'Updated assignment was not returned with its attachment and score',
    );
  }
  const studentLoginResponse = await fetch(
    new URL(`${base.pathname}/auth/login`, base.origin),
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        identifier: 'DEMO-HV-05',
        password: process.env.DEMO_PASSWORD ?? 'Password@123',
      }),
    },
  );
  if (!studentLoginResponse.ok) throw new Error('Student login failed');
  const studentLogin = await studentLoginResponse.json();
  const studentToken = studentLogin.data?.accessToken;
  const submitResponse = await fetch(
    new URL(`${base.pathname}/assignments/${assignmentId}/submit`, base.origin),
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${studentToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        content: 'Speaking smoke submission',
        fileUrls: [{ name: audioName, url: audioUrl, fileType: 'DOCUMENT', type: 'audio', durationSeconds: 3 }],
      }),
    },
  );
  if (!submitResponse.ok) {
    throw new Error(`Student submission failed: ${submitResponse.status} ${await submitResponse.text()}`);
  }
  console.log(
    'Authenticated TXT, audio/x-wav, ZIP, RAR upload and student submission: PASS',
  );
} finally {
  if (assignmentId) {
    const prisma = new PrismaClient();
    try {
      await prisma.assignment.delete({ where: { id: assignmentId } });
    } finally {
      await prisma.$disconnect();
    }
  }
  if (localFile) await unlink(localFile).catch(() => {});
  if (localAudioFile) await unlink(localAudioFile).catch(() => {});
  for (const archiveFile of localArchiveFiles) {
    await unlink(archiveFile).catch(() => {});
  }
}
