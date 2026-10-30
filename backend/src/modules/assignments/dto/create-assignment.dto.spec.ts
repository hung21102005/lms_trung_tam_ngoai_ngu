import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import {
  CreateAssignmentDto,
  SubmitAssignmentDto,
  UpdateAssignmentDto,
} from './create-assignment.dto.js';

describe('Assignment attachment DTOs', () => {
  const attachment = {
    name: 'rubric.pdf',
    url: '/uploads/assignments/rubric.pdf',
    fileType: 'DOCUMENT',
    size: 1024,
  };

  it('preserves attachment objects when implicit conversion is enabled', async () => {
    const dto = plainToInstance(
      CreateAssignmentDto,
      { title: 'Writing Task', attachments: [attachment] },
      { enableImplicitConversion: true },
    );

    expect(await validate(dto, { whitelist: true })).toHaveLength(0);
    expect(dto.attachments).toEqual([attachment]);
  });

  it('preserves objects when updating an assignment or submitting files', async () => {
    const update = plainToInstance(
      UpdateAssignmentDto,
      { attachments: [attachment] },
      { enableImplicitConversion: true },
    );
    const submission = plainToInstance(
      SubmitAssignmentDto,
      { fileUrls: [attachment] },
      { enableImplicitConversion: true },
    );

    expect(await validate(update, { whitelist: true })).toHaveLength(0);
    expect(await validate(submission, { whitelist: true })).toHaveLength(0);
    expect(update.attachments).toEqual([attachment]);
    expect(submission.fileUrls).toEqual([attachment]);
  });
});
